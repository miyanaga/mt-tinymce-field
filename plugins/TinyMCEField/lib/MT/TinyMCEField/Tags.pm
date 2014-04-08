package MT::TinyMCEField::Tags;

use strict;

use MT::TinyMCEField::Util;
use MT::Util qw(caturl);
use MT::App::CMS;

sub hdlr_LoadTinyMCEScriptsSafety {
    my ( $ctx, $args ) = @_;
    my $app = MT->instance();
    my $_type = $app->param('_type');

    # Loading only once
    return '' if MT->request->cache('__tinymcescripts');

    # Get editor param
    my %editors;
    MT::App::CMS::setup_editor_param(MT->instance, \%editors);

    # Remove except for tinymce
    delete $editors{editors}->{$_}
        foreach grep { $_ ne 'tinymce' } keys %{$editors{editors}};

    # Set as locals
    my $vars = $ctx->{__stash}{vars};
    local @$vars{keys %editors} = values %editors;
    local $vars->{js_include} = '';
    # local $vars->{object_type} = 'dummy-tinymce-field';

    # Insert editor scripts
    my $tmpl = q{
<script type="text/javascript" src="<$mt:var name="static_uri"$>js/edit.js?v=<$mt:var name="mt_version_id" escape="url"$>"></script>
<mt:include name="include/editor_script.tmpl">
<mt:var name="js_include">
    };
    my $builder = $ctx->stash('builder');
    my $tokens = $builder->compile($ctx, $tmpl);
    defined( my $js = $builder->build($ctx, $tokens) )
        or return $ctx->error($builder->errstr);

    # Wrap javascript and load lazy to avoid conflict against regular editor
    $js =~ s!</script>!<\\/script>!g;
    $js =~ s!\r?\n!\\n!g;
    $js =~ s!'!\\'!g;

    my $out = '';
    $out .= qq{<script type="text/javascript">(MT && MT.Editor) || document.write('$js');</script>};
    $out .= <<'JS';
<style type="text/css">
    /* FIXME editors are default seems hidden */
    .tinymce-field-container .mt-editor-manager-wrap { display: block !important; }
</style>
<script type="text/javascript">
jQuery(function($) {
    // Override EditorStrategy.Multi to contain TinyMCEFields
    var ESM = MT.App.EditorStrategy.Multi;
    var _create = ESM.prototype.create;
    var _set = ESM.prototype.set;

    MT.App.EditorStrategy.Multi.prototype.create = function(app, ids, format) {
        $('.tinymce-field-container textarea').each(function(i) {
            ids.push(this.id);
        });
        _create.apply(this, arguments);
    };
});
</script>
JS

    # Add Blog ID Data
    if ($_type eq 'category' or $_type eq 'folder') {
        $out .= q{<input type="hidden" name="blog_id" value="<$mt:BlogID$>" id="blog-id" />};
    }

    # Mark as loaded in this context
    MT->request->cache('__tinymcescripts', 1);

    $out;
}

1;
__END__