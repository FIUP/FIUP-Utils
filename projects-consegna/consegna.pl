#!/usr/bin/perl

$cfg="/var/conf/laboratori.cfg";

my %avvisi=( "basidati" => "basidati2015" ) ;   #AS: ammetto che non e` elegante avere due tabelle diverse: questa e laboratori.cfg


my $regex=undef;
use Getopt::Long;
GetOptions( "preg|regex=s" => \$regex ) or die("Error in command line arguments - Usage: $0 nomeconsegna [--regex preg]\n");


if (@ARGV!=1) {
    print STDERR "\nUSO PREVISTO:\n----\n  dipXYZ:~/directory\$ consegna NomeProgetto\n----\n";
    print STDERR "---- Cioe` va indicato il nome del progetto e verranno consegnati\n";
    print STDERR "---- i file della directory da cui si da' il comando.\n";
    print STDERR "---- Esempio: Con i seguenti comandi:\n----\n";
    print STDERR "  dipXYZ:~\$ mkdir progetto-ES.1\n";
    print STDERR "  dipXYZ:~\$ cd    progetto-ES.1\n";
    print STDERR "  dipXYZ:~/progetto-ES.1\$ emacs programma.c\n";
    print STDERR "  ..... scrivo il mio programma e lo salvo .....\n";
    print STDERR "  dipXYZ:~/progetto-ES.1\$ consegna Programmazione-ES.1\n";
    print STDERR "----\n---- Sono consegnati i file della directory progetto-ES.1\n----\n";
    print STDERR "----\n---- NB: Questo purche\` sia la directory corrente\n----\n";
    exit 1;
}

open(CFG,"$cfg") || die "Can't open configuration file [$cfg]: $!\n";
$found="no";
while(($found eq "no") && ($line=<CFG>)) {
    chomp $line;
    # Salto i commenti
    if ($line =~ /^\s*\#.*/ ){
	next;
    }

    ($line                          )=split(/\#/     ,$line);     #AS: per permettere i commenti a fine riga
    ($prg ,$descrizione,@acopysuffix)=split(/\s*:\s*/,$line);     #AS: messo \s*:\s* per poter indentare il file
    if ($prg eq $ARGV[0]) {
	$found="yes";
    }
}
close(CFG);

if ( exists( $avvisi{ $ARGV[0] } ) ) {
    print 
"
/**                      ATTENZIONE: non hai consegnato nulla                   **/
/**                                                                             **/
/**                                                                             **/
/** Per l'anno accademico corrente la consegna potrebbe essere:     consegna $avvisi{ $ARGV[0] }     **/
/** Ad ogni modo chiedi maggiori informazioni al docente o ai tecnici del Servizio Calcolo    **/
/**                                                                             **/
/**                                                                             **/
/**                      ATTENZIONE: non hai consegnato nulla                   **/

";
    exit 1;
}



if ($found eq "no") {
    print STDERR "ERRORE: Progetto non attivato o nome del progetto errato; intendevi uno dei seguenti?\n\n";
    system ( ' cat /var/conf/laboratori.cfg | grep -v -E "^\s*#|^\s*$" | cut -d ":" -f 1 | sort 1>&2 ' );
    print STDERR "\nERRORE: Fai attenzione al fatto che un particolare progetto si consegna solo in Torre o solo al Paolotti\n";
    exit 1;
} elsif ($found eq "yes") {
    $thisdir=`pwd`;
    chop($thisdir);
    print STDOUT "Consegna di [$thisdir] per il progetto [$prg]\n\n";
    print STDOUT "Descrizione: [$descrizione]\n\n";
} else {
    print STDERR "ERRORE: Programma in errore. Avvisare il personale\n";
    exit 1;
}

# prende i contenuti della directory dell'utente e li pone nella directory
# temporanea

$tempfile = "/tmp/.consegna.tmp.$$";
$archivio = "/tmp/$prg-$$.tgz";

opendir THISDIR, "." or die "Non posso aprire questa directory\n";
@allfile = readdir(THISDIR);
close THISDIR;

open (OUT, ">$tempfile");
for $i (0..@allfile-1) {
    if (($allfile["$i"] ne 'core')        &&
        ($allfile["$i"] ne 'octave-core') &&
	($allfile["$i"] !~ /\~/)          &&
	($allfile["$i"] ne '..')          &&
	($allfile["$i"] ne '.' )         ){

	$file = $allfile["$i"];
	if ( not defined $regex ) {
	    print OUT "$file\n";
	} elsif ( $file =~ /$regex/i ) {
	    print OUT "$file\n";
	} 
    }
}
close(OUT);
open(OUT,"<$tempfile");

if (($ENV{"USER"} eq "") or ($ENV{"LOGNAME"} eq "")) {
    $idout=`id`;
    ($uid, $gid, $groups) = split /\s/, $idout;
    if ($uid =~ /^uid=\d+\(([a-z]+)\)$/) {
	$ENV{"USER"} = $1;
	$ENV{"LOGNAME"} = $1;
    } else {
	print STDERR "Problemi: non riesco a capire chi sei:\n";
	exit 1;
    }
}

system("/bin/tar cvfz $archivio --files-from $tempfile");

opendir THISDIR, "." or die "Non posso aprire questa directory\n";
@l1_files = grep { ! /(^\.)|core|~$/  && ( -f $_ || -l $_ || -d $_ ) ; } readdir THISDIR;
close THISDIR;
print STDERR "\nAttenzione: [Forse stai consegnando una cartella vuota, controlla bene l'elenco dei file consegnati...]\n\n" unless @l1_files ;

for $suffix ( @acopysuffix ){

    chomp $suffix;
    $suffix =~ s/^\s+//;
    $suffix =~ s/\s+$//;

    if ( -r("/var/conf/bin/acopy.$suffix") and -x( "/var/conf/bin/acopy.$suffix") ) {
	system("/var/conf/bin/acopy.$suffix $archivio"); 
    }
    else {
	print STDERR "\n\nERRORE: Programma in errore, non posso consegnare via /var/conf/bin/acopy.$suffix. Avvisare il personale\n\n";
	exit 1;     
    }
}

unlink("$tempfile");
unlink("$archivio");

exit 0;

