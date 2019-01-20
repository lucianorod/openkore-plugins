package configChanger;

use encoding 'utf8';
use Log qw(message);

Plugins::register("configChanger", "altera arquivos de configuração", \&unload);

my $cmd = Commands::register(
	['changeConfig','change config',\&changeConfig],
);

sub changeConfig {
	my (undef, $args) = @_;

	$baseControlFolder = $Settings::controlFolders[0];
	$pluginFolderInControl = File::Spec->catdir($baseControlFolder, $args);

	my @fileList = getFiles($pluginFolderInControl);

	if (defined $args) {
		loadFiles($pluginFolderInControl, @fileList);
	} else {
		loadFiles($baseControlFolder, @fileList);
	}
}

sub loadFiles {
	my ($pluginFolderInControl, @fileList) = @_;
	my %fileHash;

	foreach my $file (@{$Settings::files->getItems}) {
		next if ($file =~ /^\./);
		my (undef, undef, $fileName) = File::Spec->splitpath($file->{name});
		$fileHash{$fileName} = $file;
	}

	foreach (@fileList) {

		if (exists $fileHash{$_}) {

			my $file = $fileHash{$_};
			my (undef, undef, $fileName) = File::Spec->splitpath($file->{name});

			my $newFilePath = File::Spec->catdir($pluginFolderInControl, $fileName);
			my $reloadingFile = $Settings::files->get($file->{index});

			if ($file->{name} ne $fileName) {

				$reloadingFile->{name} = $newFilePath;

				if (ref($reloadingFile->{loader}) eq 'ARRAY') {
					my @array = @{$reloadingFile->{loader}};
					my $loader = shift @array;
					$loader->($newFilePath, @array);
				} else {
					$reloadingFile->{loader}->($newFilePath);
				}
				message("Loading ".$newFilePath."...\n", "info");
			}
		}
	}
}

sub getFiles {
	my ($folder) = @_;

	opendir my $d, $folder;
	my @fileList = readdir($d);
	closedir $d;

	return @fileList;
}

sub unload {
	Commands::unregister($cmd);
	undef $cmd;
}
