class Pipenv < Formula
  include Language::Python::Virtualenv

  desc "Python dependency management tool"
  homepage "https://github.com/pypa/pipenv"
  url "https://files.pythonhosted.org/packages/8c/46/4743dd471f4f04f0f257237410dc3a06d50df566e77be864569a7420e651/pipenv-2024.3.0.tar.gz"
  sha256 "bd542b63103a684a909e3af26cd11d2cc39b0acf4a2a8525835b18360e58de9a"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "4cc701a0ea32925c8997845fc2bfaf4f191d696af48d9310e49140934ff7e8da"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "4cc701a0ea32925c8997845fc2bfaf4f191d696af48d9310e49140934ff7e8da"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "4cc701a0ea32925c8997845fc2bfaf4f191d696af48d9310e49140934ff7e8da"
    sha256 cellar: :any_skip_relocation, sonoma:        "d7646504566a5532a7e17f750d60d8ae367bf94774cb107e83863506e78c5585"
    sha256 cellar: :any_skip_relocation, ventura:       "d7646504566a5532a7e17f750d60d8ae367bf94774cb107e83863506e78c5585"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "9cdbd91797b50551c23c8798354a4a5e03073283daac93116afaf6d901013744"
  end

  depends_on "certifi"
  depends_on "python@3.13"

  def python3
    "python3.13"
  end

  resource "distlib" do
    url "https://files.pythonhosted.org/packages/0d/dd/1bec4c5ddb504ca60fc29472f3d27e8d4da1257a854e1d96742f15c1d02d/distlib-0.3.9.tar.gz"
    sha256 "a60f20dea646b8a33f3e7772f74dc0b2d0772d2837ee1342a00645c81edf9403"
  end

  resource "filelock" do
    url "https://files.pythonhosted.org/packages/9d/db/3ef5bb276dae18d6ec2124224403d1d67bccdbefc17af4cc8f553e341ab1/filelock-3.16.1.tar.gz"
    sha256 "c249fbfcd5db47e5e2d6d62198e565475ee65e4831e2561c8e313fa7eb961435"
  end

  resource "packaging" do
    url "https://files.pythonhosted.org/packages/51/65/50db4dda066951078f0a96cf12f4b9ada6e4b811516bf0262c0f4f7064d4/packaging-24.1.tar.gz"
    sha256 "026ed72c8ed3fcce5bf8950572258698927fd1dbda10a5e981cdf0ac37f4f002"
  end

  resource "platformdirs" do
    url "https://files.pythonhosted.org/packages/13/fc/128cc9cb8f03208bdbf93d3aa862e16d376844a14f9a0ce5cf4507372de4/platformdirs-4.3.6.tar.gz"
    sha256 "357fb2acbc885b0419afd3ce3ed34564c13c9b95c89360cd9563f73aa5e2b907"
  end

  resource "setuptools" do
    url "https://files.pythonhosted.org/packages/ed/22/a438e0caa4576f8c383fa4d35f1cc01655a46c75be358960d815bfbb12bd/setuptools-75.3.0.tar.gz"
    sha256 "fba5dd4d766e97be1b1681d98712680ae8f2f26d7881245f2ce9e40714f1a686"
  end

  resource "virtualenv" do
    url "https://files.pythonhosted.org/packages/8c/b3/7b6a79c5c8cf6d90ea681310e169cf2db2884f4d583d16c6e1d5a75a4e04/virtualenv-20.27.1.tar.gz"
    sha256 "142c6be10212543b32c6c45d3d3893dff89112cc588b7d0879ae5a1ec03a47ba"
  end

  def install
    virtualenv_install_with_resources

    generate_completions_from_executable(libexec/"bin/pipenv", shells:                 [:fish, :zsh],
                                                               shell_parameter_format: :click)
  end

  # Avoid relative paths
  def post_install
    lib_python_path = Pathname.glob(libexec/"lib/python*").first
    lib_python_path.each_child do |f|
      next unless f.symlink?

      realpath = f.realpath
      rm f
      ln_s realpath, f
    end
  end

  test do
    ENV["LC_ALL"] = "en_US.UTF-8"
    assert_match "Commands", shell_output(bin/"pipenv")
    system bin/"pipenv", "--python", which(python3)
    system bin/"pipenv", "install", "requests"
    system bin/"pipenv", "install", "boto3"
    assert_predicate testpath/"Pipfile", :exist?
    assert_predicate testpath/"Pipfile.lock", :exist?
    assert_match "requests", (testpath/"Pipfile").read
    assert_match "boto3", (testpath/"Pipfile").read
  end
end
