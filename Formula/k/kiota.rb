class Kiota < Formula
  desc "OpenAPI based HTTP Client code generator"
  homepage "https://aka.ms/kiota/docs"
  url "https://github.com/microsoft/kiota/archive/refs/tags/v1.20.0.tar.gz"
  sha256 "2090ed62884c77ae26ba1f0c37b9c250c2dc7b7229c0e18fbdfcb67c8b2c96bc"
  license "MIT"
  head "https://github.com/microsoft/kiota.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "773165c339daae8be3322b8cdea5245793cca4dfbaba1d52885f5729d8e62faa"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "683b449961baff5e428a13c279ce3ad921da43a40b2f50975ea14a463a2fa72d"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "96ee70830d45bfddaeacbb1c81dddc47f0bca33cdb0a03a9b9abddf54cf8b6f0"
    sha256 cellar: :any_skip_relocation, sonoma:        "c5060354f292aba6b9d7d70d93c86815ad25dd6fd4653f913cf7a13ad6069527"
    sha256 cellar: :any_skip_relocation, ventura:       "f2dc54748aa339a651604f7a1a748f71f455ab1d9cc8cee66696aa40f048c69a"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "c65a764bd7f811755436ca5149f166b46a4277611bb188ba9ed7eeb2ba7ae0fb"
  end

  depends_on "dotnet"

  def install
    dotnet = Formula["dotnet"]
    os = OS.mac? ? "osx" : OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s

    args = %W[
      --configuration Release
      --framework net#{dotnet.version.major_minor}
      --output #{libexec}
      --runtime #{os}-#{arch}
      --no-self-contained
      -p:TargetFramework=net#{dotnet.version.major_minor}
      -p:PublishSingleFile=true
      -p:Version=#{version}
    ]

    system "dotnet", "publish", "src/kiota/kiota.csproj", *args

    (bin/"kiota").write_env_script libexec/"kiota",
      DOTNET_ROOT: "${DOTNET_ROOT:-#{dotnet.opt_libexec}}"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kiota --version")

    info_output = shell_output("#{bin}/kiota info")
    assert_match "Go          Stable", info_output
    assert_match "Python      Stable", info_output

    search_output = shell_output("#{bin}/kiota search github")
    assert_match "apisguru::github.com                            GitHub v3 REST API", search_output
  end
end
