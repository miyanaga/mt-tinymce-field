package MT::TinyMCEField::Util;

use strict;

use MT;
use base 'Exporter';

our @EXPORT = qw(plugin tinymce_plugin);

sub plugin {
    MT->component('TinyMCEField');
}

sub tinymce_plugin {
    MT->component('TinyMCE');
}

1;
__END__