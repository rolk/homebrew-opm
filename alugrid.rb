# This file is licensed under the GNU General Public License v3.0
require 'formula'

class Alugrid < Formula
  homepage 'http://aam.mathematik.uni-freiburg.de/IAM/Research/alugrid/'
  url 'http://aam.mathematik.uni-freiburg.de/IAM/Research/alugrid/ALUGrid-1.52.tar.gz'
  sha1 '3e5da3f5b88ea61dcd31f952f9dde135af634c62'

  depends_on 'autoconf' => :build
  depends_on 'automake' => :build
  depends_on 'libtool' => :build
  depends_on 'metis' => :recommended 
  option 'with-mpi', 'Enable MPI support'
  depends_on MPIDependency.new(:cxx) if build.with? "mpi"
  option 'with-c++11' if MacOS.version >= :lion

  def patches
    # remove the misguided idea that the major number should always be increased
    # to avoid having zero in that position, and add minor version to compatibility
    # version to make it only compatible with itself
    DATA
  end
  
  def install
    # parse version number
    major = version.to_s.split('.')[0]
    minor = version.to_s.split('.')[1]
    name = 'alugrid'

    # standard arguments: we must know where to put the library
    args = %W[--prefix=#{prefix}
              --enable-shared]

    # if we are building with metis support, then inform where it is
    if build.with? 'metis'
      args << "--with-metis=#{Formula.factory('metis').opt_prefix}"
    end

    # use C++11 runtime library
    if MacOS.version >= :lion and build.with? 'c++11'
      ENV.append 'CXX', '-std=c++11'
      if ENV.compiler == :clang
        ENV.append 'CXX', '-stdlib=libc++'
      end
    end

    # there is a test which includes stdlib.h, which apparently needs
    # this define if we are using clang
    if build.with? 'mpi' and ENV.compiler == :clang
      ENV.append 'CXXFLAGS', '-D_WCHAR_T'
    end

    # go figure out where the rest we need on the system is
    system './configure', *args

    # add version information to the generated Makefile; we cannot modify Makefile.am,
    # because Homebrew version of automake is not compatible with the one used to
    # generate the files in the sourceball. notice the escaping of the backslash since
    # we use double quoted string to inject the library name and version
    system 'sed', '-i', '.bak',
      "s/\\(^.*CXXLINK.*lib#{name}_la_LIBADD.*$\\)/\\1 -version-info #{major}:#{minor}:0/",
      'src/Makefile'

    # copy the built files into their target directories
    system 'make', 'install'

    # parse version number
    major = version.to_s.split('.')[0]
    minor = version.to_s.split('.')[1]

    # rearrange so that we get the correct symlink
    cd lib do
      mv "lib#{name}.#{major}.dylib", "lib#{name}.#{version}.dylib"
      rm_f "lib#{name}.#{major}.dylib"
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.#{major}.dylib"
      rm_f "lib#{name}.dylib"
      ln_s "lib#{name}.#{major}.dylib", "lib#{name}.dylib"
    end
  end
end

__END__
--- old/ltmain.sh
+++ new/ltmain.sh
@@ -7385,14 +7385,13 @@
 	  # verstring for coding it into the library header
 	  func_arith $current - $age
 	  major=.$func_arith_result
 	  versuffix="$major.$age.$revision"
 	  # Darwin ld doesn't like 0 for these options...
-	  func_arith $current + 1
-	  minor_current=$func_arith_result
-	  xlcverstring="${wl}-compatibility_version ${wl}$minor_current ${wl}-current_version ${wl}$minor_current.$revision"
-	  verstring="-compatibility_version $minor_current -current_version $minor_current.$revision"
+	  minor_current=$current
+	  xlcverstring="${wl}-compatibility_version ${wl}$minor_current.$revision ${wl}-current_version ${wl}$minor_current.$revision"
+	  verstring="-compatibility_version $minor_current.$revision -current_version $minor_current.$revision"
 	  ;;
 
 	freebsd-aout)
 	  major=".$current"
 	  versuffix=".$current.$revision";
--- old/src/serial/gitter_sti.cc
+++ new/src/serial/gitter_sti.cc
@@ -508,7 +508,7 @@
 
 void Gitter :: backup (ostream & out) 
 {
-  assert (debugOption (20) ? (cout << "**INFO Gitter :: backup (ostream & = " << out << ") " << endl, 1) : 1) ;
+  assert (debugOption (20) ? (cout << "**INFO Gitter :: backup (ostream & = " << &out << ") " << endl, 1) : 1) ;
   {
     AccessIterator <hedge_STI> :: Handle fw (container ()) ;
     for (fw.first(); !fw.done(); fw.next()) fw.item ().backup (out) ; 
@@ -525,7 +525,7 @@
 }
 
 void Gitter ::restore (istream & in) {
-  assert (debugOption (20) ? (cout << "**INFO Gitter :: restore (istream & = " << in << ") " << endl, 1) : 1) ;  
+  assert (debugOption (20) ? (cout << "**INFO Gitter :: restore (istream & = " << &in << ") " << endl, 1) : 1) ;  
   {
     AccessIterator < hedge_STI > :: Handle ew (container ());
     for (ew.first () ; !ew.done () ; ew.next ()) ew.item ().restore (in) ;
--- old/src/duneinterface/gitter_dune_pll_impl.cc
+++ new/src/duneinterface/gitter_dune_pll_impl.cc
@@ -1899,7 +1899,7 @@
 void GitterDunePll ::restore (istream & in) 
 {
   typedef Gitter :: Geometric :: BuilderIF BuilderIF;
-  assert (debugOption (20) ? (cout << "**INFO GitterDunePll :: restore (istream & = " << in << ") " << endl, 1) : 1) ;
+  assert (debugOption (20) ? (cout << "**INFO GitterDunePll :: restore (istream & = " << &in << ") " << endl, 1) : 1) ;
   {
     AccessIterator < hedge_STI > :: Handle ew (container ());
     for (ew.first () ; !ew.done () ; ew.next ()) ew.item ().restore (in) ;
