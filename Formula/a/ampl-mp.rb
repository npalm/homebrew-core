class AmplMp < Formula
  desc "Open-source library for mathematical programming"
  homepage "https://www.ampl.com/"
  url "https://github.com/ampl/mp/archive/refs/tags/v4.0.0.tar.gz"
  sha256 "9ac4b03dd03285cfcf998d81b53410611dd3ba0515463b70980965ec51e29f0f"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    rebuild 1
    sha256 cellar: :any,                 arm64_sequoia: "d02c9a51954b17ab0a6caa31093daa7be212239b957d2224b773aaaa19b89c59"
    sha256 cellar: :any,                 arm64_sonoma:  "02f9efaecf470dffc6bff5b71530d0245b342f0e3805f73a5741b15a175e348a"
    sha256 cellar: :any,                 arm64_ventura: "cf8589ed55bdfa5612fe9f4efc698eed1000e332446900798b1d4ebcd9f4e77e"
    sha256 cellar: :any,                 sonoma:        "fdf52601bd4c9990a80d1a14600d7c8649f2597bf4af38c966f9f806835eff44"
    sha256 cellar: :any,                 ventura:       "48756d110b0bac36eec0f33e181ad12f68632cb3087ccebb8451ef1d31798294"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "14117080e712ec6bcfd79084440b9264783a4567b9f31368bf8fa7109d718f58"
  end

  depends_on "cmake" => :build

  def install
    args = %W[
      -DAMPL_LIBRARY_DIR=#{libexec}/bin
      -DBUILD_SHARED_LIBS=ON
      -DBUILD_TESTS=OFF
      -DCMAKE_INSTALL_RPATH=#{rpath};#{rpath(source: libexec/"bin")}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <stdlib.h>
      #include "mp/ampls-c-api.h"

      int main() {
          AMPLS_MP_Solver* solver = (AMPLS_MP_Solver*)malloc(sizeof(AMPLS_MP_Solver));
          free(solver);
          return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}/mp", "-L#{lib}", "-lmp", "-o", "test"
    system "./test"
  end
end
