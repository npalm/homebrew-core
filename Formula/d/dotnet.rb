class Dotnet < Formula
  desc ".NET Core"
  homepage "https://dotnet.microsoft.com/"
  license "MIT"
  head "https://github.com/dotnet/dotnet.git", branch: "main"

  stable do
    # Source-build tag announced at https://github.com/dotnet/source-build/discussions
    url "https://github.com/dotnet/dotnet/archive/refs/tags/v9.0.0-rc.2.24473.5.tar.gz"
    sha256 "56f446bb618ac3c5c1bdf3ae2028d0bd5d549538d172e1d7f23eb1df0eee26d6"
    version "9.0.0"

    resource "release.json" do
      url "https://github.com/dotnet/dotnet/releases/download/v9.0.0-rc.2.24473.5/release.json"
      sha256 "0b487c52c61fa289195883a0fdd1fe89953a4e35d3af02263ce587ac7c3d1696"
    end
  end

  bottle do
    sha256 cellar: :any,                 arm64_sequoia: "197cb068d41882513946c97853080a27b7c314ffd8f42296b663d2a6a19277c4"
    sha256 cellar: :any,                 arm64_sonoma:  "ee8e38b1f895f854eb38256ce40ae985613b2c005881a64d58de86a7e0b9e24d"
    sha256 cellar: :any,                 arm64_ventura: "474fd3ad1582cf4f406654ec9b015e975569705c451e7f55d1a609a35b2da9ad"
    sha256 cellar: :any,                 sonoma:        "ef18da376e2734a3b327840e99aac667dd43b5c797e6b651aa875ed56644e2c4"
    sha256 cellar: :any,                 ventura:       "75c23fb3c05ac68ec3a3c22203e6829a8f80f5a2f22a3453bce1a4eff83338ad"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "e8bc8e2a21f664c9e49fba79e66c6e0fe53d8ad2eba046703ad536e47e5bb675"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "rapidjson" => :build
  depends_on "brotli"
  depends_on "icu4c@76"
  depends_on "openssl@3"

  uses_from_macos "python" => :build, since: :catalina
  uses_from_macos "krb5"
  uses_from_macos "zlib"

  on_macos do
    depends_on "grep" => :build # grep: invalid option -- P
  end

  on_sonoma do
    depends_on xcode: :build if DevelopmentTools.clang_build_version == 1600
  end

  on_linux do
    depends_on "libunwind"
    depends_on "lttng-ust"
  end

  def install
    if OS.mac?
      ENV.prepend_path "PATH", Formula["grep"].libexec/"gnubin"
    else
      icu4c_dep = deps.find { |dep| dep.name.match?(/^icu4c(@\d+)?$/) }
      ENV.append_path "LD_LIBRARY_PATH", icu4c_dep.to_formula.opt_lib

      # Work around build script getting stuck when running shutdown command on Linux
      # TODO: Try removing in the next release
      # Ref: https://github.com/dotnet/source-build/discussions/3105#discussioncomment-4373142
      inreplace "build.sh", '"$CLI_ROOT/dotnet" build-server shutdown', ""
      inreplace "repo-projects/Directory.Build.targets",
                '"$(DotnetTool) build-server shutdown --vbcscompiler"',
                '"true"'
    end

    args = ["--clean-while-building", "--source-build", "--with-system-libs", "brotli+libunwind+rapidjson+zlib"]
    if build.stable?
      args += ["--release-manifest", "release.json"]
      odie "Update release.json resource!" if resource("release.json").version != version
      buildpath.install resource("release.json")
    end

    system "./prep-source-build.sh"
    # We unset "CI" environment variable to work around aspire build failure
    # error MSB4057: The target "GitInfo" does not exist in the project.
    # Ref: https://github.com/Homebrew/homebrew-core/pull/154584#issuecomment-1815575483
    with_env(CI: nil) do
      system "./build.sh", *args
    end

    libexec.mkpath
    tarball = buildpath.glob("artifacts/*/Release/dotnet-sdk-*.tar.gz").first
    system "tar", "--extract", "--file", tarball, "--directory", libexec
    doc.install libexec.glob("*.txt")
    (bin/"dotnet").write_env_script libexec/"dotnet", DOTNET_ROOT: libexec

    bash_completion.install "src/sdk/scripts/register-completions.bash" => "dotnet"
    zsh_completion.install "src/sdk/scripts/register-completions.zsh" => "_dotnet"
    man1.install buildpath.glob("src/sdk/documentation/manpages/sdk/*.1")
    man7.install buildpath.glob("src/sdk/documentation/manpages/sdk/*.7")
  end

  def caveats
    <<~TEXT
      For other software to find dotnet you may need to set:
        export DOTNET_ROOT="#{opt_libexec}"
    TEXT
  end

  test do
    target_framework = "net#{version.major_minor}"

    (testpath/"test.cs").write <<~CSHARP
      using System;

      namespace Homebrew
      {
        public class Dotnet
        {
          public static void Main(string[] args)
          {
            var joined = String.Join(",", args);
            Console.WriteLine(joined);
          }
        }
      }
    CSHARP

    (testpath/"test.csproj").write <<~XML
      <Project Sdk="Microsoft.NET.Sdk">
        <PropertyGroup>
          <OutputType>Exe</OutputType>
          <TargetFrameworks>#{target_framework}</TargetFrameworks>
          <PlatformTarget>AnyCPU</PlatformTarget>
          <RootNamespace>Homebrew</RootNamespace>
          <PackageId>Homebrew.Dotnet</PackageId>
          <Title>Homebrew.Dotnet</Title>
          <Product>$(AssemblyName)</Product>
          <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
        </PropertyGroup>
        <ItemGroup>
          <Compile Include="test.cs" />
        </ItemGroup>
      </Project>
    XML

    system bin/"dotnet", "build", "--framework", target_framework, "--output", testpath, testpath/"test.csproj"
    output = shell_output("#{bin}/dotnet run --framework #{target_framework} #{testpath}/test.dll a b c")
    # We switched to `assert_match` due to progress status ANSI codes in output.
    # TODO: Switch back to `assert_equal` once fixed in release.
    # Issue ref: https://github.com/dotnet/sdk/issues/44610
    assert_match "#{testpath}/test.dll,a,b,c\n", output
  end
end
