{ lib, stdenv, fetchurl, cups, dpkg, gnused, makeWrapper, ghostscript, file
, a2ps, coreutils, gnugrep, which, gawk }:

let
  version = "3.0.0";
  model = "dcpj132w";
in rec {
  driver = stdenv.mkDerivation {
    pname = "${model}-lpr";
    inherit version;

    src = fetchurl {
      url =
        "https://download.brother.com/welcome/dlf006975/dcpj132wlpr-${version}-1.i386.deb";
      sha256 =
        "e73b551016a5de13b5c95e042958d3491b7cd9c148e02480188c6ff08797cb77";
    };

    nativeBuildInputs = [ dpkg makeWrapper ];
    buildInputs = [ cups ghostscript a2ps gawk ];
    unpackPhase = "dpkg-deb -x $src $out";

    installPhase = ''
      substituteInPlace $out/opt/brother/Printers/${model}/lpd/filter${model} \
      --replace /opt "$out/opt" 

      patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
      $out/opt/brother/Printers/${model}/lpd/br${model}filter


      mkdir -p $out/lib/cups/filter/
      ln -s $out/opt/brother/Printers/${model}/lpd/filter${model} $out/lib/cups/filter/brother_lpdwrapper_${model}
      
      # ugly fix for accessing the FHS path /opt, hardcoded in br${model}filter 
      sed -i 's|/opt|ropt|g' $out/opt/brother/Printers/${model}/lpd/br${model}filter
      ln -s $out/opt $out/ropt

      wrapProgram $out/opt/brother/Printers/${model}/lpd/filter${model} \
        --run "cd $out" \
        --prefix PATH ":" ${
          lib.makeBinPath [
            gawk
            ghostscript
            a2ps
            file
            gnused
            gnugrep
            coreutils
            which
          ]
        }
    '';

    meta = with lib; {
      homepage = "http://www.brother.com/";
      description = "Brother ${model} printer driver";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      license = licenses.unfree;
      platforms = platforms.linux;
      downloadPage =
        "https://support.brother.com/g/b/downloadlist.aspx?c=gb&lang=en&prod=${model}_all&os=128";
      maintainers = with maintainers; [ marcovergueira ];
    };
  };

  cupswrapper = stdenv.mkDerivation {
    pname = "${model}-cupswrapper";
    inherit version;

    src = fetchurl {
      url =
        "https://download.brother.com/welcome/dlf006977/dcpj132wcupswrapper-${version}-1.i386.deb";
      sha256 =
        "678d69f4dc7c19b76a2dd89b213b6176dda72de3e34b95cde035a15b0bccc104";

    };

    nativeBuildInputs = [ dpkg makeWrapper ];
    buildInputs = [ cups ghostscript a2ps gawk ];
    unpackPhase = "dpkg-deb -x $src $out";

    installPhase = ''
      for f in $out/opt/brother/Printers/${model}/cupswrapper/cupswrapper${model}; do
        wrapProgram $f --prefix PATH : ${
          lib.makeBinPath [ coreutils ghostscript gnugrep gnused ]
        }
      done

      mkdir -p $out/share/cups/model
      ln -s $out/opt/brother/Printers/${model}/cupswrapper/brother_${model}_printer_en.ppd $out/share/cups/model/
    '';

    meta = with lib; {
      homepage = "http://www.brother.com/";
      description = "Brother ${model} printer CUPS wrapper driver";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      license = licenses.unfree;
      platforms = platforms.linux;
      downloadPage =
        "https://support.brother.com/g/b/downloadlist.aspx?c=gb&lang=en&prod=${model}_all&os=128";
      maintainers = "mjod";   
    };
  };
}
