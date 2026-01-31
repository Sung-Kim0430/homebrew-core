class Litecli < Formula
  include Language::Python::Virtualenv

  desc "CLI for SQLite Databases with auto-completion and syntax highlighting"
  homepage "https://github.com/dbcli/litecli"
  url "https://files.pythonhosted.org/packages/e3/d5/afec99cc3eaba96214d77e76438d7fe5e6ea54704b0e47dd97d9696ccd6c/litecli-1.17.1.tar.gz"
  sha256 "e2f7191eaba830b24dbbfc9171a495c62562df923ba1cc3b2db2652547c1bac8"
  license "BSD-3-Clause"

  bottle do
    rebuild 3
    sha256 cellar: :any,                 arm64_tahoe:   "becc6fb363f8febd1295149e5958705e146560956bd69aa902f9242926e6c919"
    sha256 cellar: :any,                 arm64_sequoia: "295f5e0ca0acb11d5436197db293d8b6876c4d8f8ca3fb82372496ebe031ff00"
    sha256 cellar: :any,                 arm64_sonoma:  "ebfdbe8b7280437b3a59c06c3a205bd3ef8b7223c82470ae6530eaf2bbe5d1d6"
    sha256 cellar: :any,                 sonoma:        "7d6b415368a5cc010d4e4babf9ffc26cd416af900f472bab13f384ee22b072f7"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "880bf2366a97870e9b6a477d37a079e3459ab7fb5c9967beccecb66abc93a805"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "261be847818fd5b2a5c9d94fd10bfb40d18ddb528fad510ebd74541042e20fd9"
  end

  depends_on "rust" => :build # for jiter
  depends_on "certifi" => :no_linkage
  depends_on "libyaml"
  depends_on "pydantic" => :no_linkage
  depends_on "python@3.14"

  uses_from_macos "sqlite"

  pypi_packages exclude_packages: %w[certifi pydantic setuptools]

  resource "cli-helpers" do
    url "https://files.pythonhosted.org/packages/3b/a3/0eead9f2b507c8f71db89984870ae9ba2e92a01ae28dda6c1b91030cac5d/cli_helpers-2.9.0.tar.gz"
    sha256 "a988745ec431ddae707f738dd0d13890b74a00a2aa0428eacd7fc1e03b206a17"
  end

  resource "click" do
    url "https://files.pythonhosted.org/packages/3d/fa/656b739db8587d7b5dfa22e22ed02566950fbfbcdc20311993483657a5c0/click-8.3.1.tar.gz"
    sha256 "12ff4785d337a1bb490bb7e9c2b1ee5da3112e94a8622f26a6c77f5d2fc6842a"
  end

  resource "configobj" do
    url "https://files.pythonhosted.org/packages/f5/c4/c7f9e41bc2e5f8eeae4a08a01c91b2aea3dfab40a3e14b25e87e7db8d501/configobj-5.0.9.tar.gz"
    sha256 "03c881bbf23aa07bccf1b837005975993c4ab4427ba57f959afdd9d1a2386848"
  end

  resource "prompt-toolkit" do
    url "https://files.pythonhosted.org/packages/a1/96/06e01a7b38dce6fe1db213e061a4602dd6032a8a97ef6c1a862537732421/prompt_toolkit-3.0.52.tar.gz"
    sha256 "28cde192929c8e7321de85de1ddbe736f1375148b02f2e17edd840042b1be855"
  end

  resource "pygments" do
    url "https://files.pythonhosted.org/packages/b0/77/a5b8c569bf593b0140bde72ea885a803b82086995367bf2037de0159d924/pygments-2.19.2.tar.gz"
    sha256 "636cb2477cec7f8952536970bc533bc43743542f70392ae026374600add5b887"
  end

  resource "sqlparse" do
    url "https://files.pythonhosted.org/packages/90/76/437d71068094df0726366574cf3432a4ed754217b436eb7429415cf2d480/sqlparse-0.5.5.tar.gz"
    sha256 "e20d4a9b0b8585fdf63b10d30066c7c94c5d7a7ec47c889a2d83a3caa93ff28e"
  end

  resource "tabulate" do
    url "https://files.pythonhosted.org/packages/ec/fe/802052aecb21e3797b8f7902564ab6ea0d60ff8ca23952079064155d1ae1/tabulate-0.9.0.tar.gz"
    sha256 "0095b12bf5966de529c0feb1fa08671671b3368eec77d7ef7ab114be2c068b3c"
  end

  resource "wcwidth" do
    url "https://files.pythonhosted.org/packages/5f/3e/3d456efe55d2d5e7938b5f9abd68333dd8dceb14e829f51f9a8deed2217e/wcwidth-0.5.2.tar.gz"
    sha256 "c022c39a02a0134d1e10810da36d1f984c79648181efcc70a389f4569695f5ae"
  end

  def install
    virtualenv_install_with_resources

    generate_completions_from_executable(bin/"litecli", shell_parameter_format: :click)
  end

  test do
    (testpath/".config/litecli/config").write <<~INI
      [main]
      table_format = tsv
      less_chatty = True
    INI

    (testpath/"test.sql").write <<~SQL
      CREATE TABLE IF NOT EXISTS package_manager (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(256)
      );
      INSERT INTO
        package_manager (name)
      VALUES
        ('Homebrew');
    SQL
    system "sqlite3 test.db < test.sql"

    require "pty"
    output = ""
    PTY.spawn("#{bin}/litecli test.db") do |r, w, _pid|
      sleep 2
      w.puts "SELECT name FROM package_manager"
      w.puts "quit"

      begin
        r.each_line { |line| output += line }
      rescue Errno::EIO
        # GNU/Linux raises EIO when read is done on closed pty
      end
    end

    # remove ANSI colors
    output.gsub!(/\e\[([;\d]+)?m/, "")
    # normalize line endings
    output.gsub!("\r\n", "\n")

    expected = <<~EOS
      name
      Homebrew
      1 row in set
    EOS

    assert_match expected, output
  end
end
