package Catmandu::Fix::bm_map;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Data::Dumper;
use Moo;

has path  => ( is => 'ro', required => 1 );
has key   => ( is => 'ro', required => 1 );
has mpath => ( is => 'ro', required => 1 );
has opts  => ( is => 'ro' );

around BUILDARGS => sub {
    my ( $orig, $class, $mpath, $path, %opts ) = @_;
    my ( $p, $key ) = parse_data_path($path) if defined $path && length $path;
    $orig->(
        $class,
        path  => $p,
        key   => $key,
        mpath => $mpath,
        opts  => \%opts
    );
};

sub fix {
    my ( $self, $data ) = @_;

    my $path  = $self->path;
    my $key   = $self->key;
    my $mpath = $self->mpath;
    my $opts  = $self->opts || {};
    $opts->{-join} = '' unless $opts->{-join};

    my $bm_pointer = $opts->{-record} || 'record';
    my $bm = $data->{$bm_pointer};

    my $fields = bm_field( $bm, $mpath );

    return $data if !@{$fields};

    my $match
        = [ grep ref, data_at( $path, $data, key => $key, create => 1 ) ]
        ->[0];

    for my $field (@$fields) {
        my $field_value = bm_subfield( $field, $mpath );

        next if is_empty($field_value);

        $field_value = [ $opts->{-value} ] if defined $opts->{-value};
        $field_value = join $opts->{-join}, @$field_value
            if defined $opts->{-join};
        $field_value = create_path( $opts->{-in}, $field_value )
            if defined $opts->{-in};
        $field_value = path_substr( $mpath, $field_value )
            unless index( $mpath, '/' ) == -1;

        if ( is_array_ref($match) ) {
            if ( is_integer($key) ) {
                $match->[$key] = $field_value;
            }
            else {
                push @{$match}, $field_value;
            }
        }
        else {
            if ( exists $match->{$key} ) {
                $match->{$key} .= $opts->{-join} . $field_value;
            }
            else {
                $match->{$key} = $field_value;
            }
        }
    }
    $data;
}

sub is_empty {
    my ($ref) = shift;
    for (@$ref) {
        return 0 if defined $_;
    }
    return 1;
}

sub path_substr {
    my ( $path, $value ) = @_;
    return $value unless is_string($value);
    if ( $path =~ /\/(\d+)(-(\d+))?/ ) {
        my $from = $1;
        my $to = defined $3 ? $3 - $from + 1 : 0;
        return substr( $value, $from, $to );
    }
    return $value;
}

sub create_path {
    my ( $path, $value ) = @_;
    my ( $p, $key, $guard ) = parse_data_path($path);
    my $leaf  = {};
    my $match = [
        grep ref,
        data_at( $p, $leaf, key => $key, guard => $guard, create => 1 )
    ]->[0];
    $match->{$key} = $value;
    $leaf;
}

# Parse a bm_path into parts
# 245abd  - field=245, subfields = a,b,d
# 012/0-4 - field=012, substring 0 to 4
# aar     - field=arr
sub parse_bm_path {
    my $path = shift;

    if ( $path =~ /(\S{3})([_a-z0-9]+)?(\/(\d+)(-(\d+))?)?/ ) {
        my $field    = $1;
        my $subfield = $2 ? "[$2]" : "[a-z0-9_]";
        my $from     = $4;
        my $to       = $6;
        return {
            field    => $field,
            subfield => $subfield,
            from     => $from,
            to       => $to
        };
    }
    else {
        return {};
    }
}

# Given a Catmandu::Importer::MAB item return for each matching field the
# array of subfields
# Usage: bm_field($data,'245');
sub bm_field {
    my ( $bm_item, $path ) = @_;
    my $bm_path = parse_bm_path($path);
    my @results = ();

    my $field = $bm_path->{field};
    $field =~ s/\*/./g;

    for (@$bm_item) {
        my ( $tag, @subfields ) = @$_;
        if ( $tag =~ /$field/ ) {
            push( @results, \@subfields );
        }
    }
    return \@results;
}

# Given a subarray of Catmandu::Importer::BILDEMARC subfields 
# it returns all the subfields that match the $subfield regex
# Usage: bm_subfield($subfields,'[a]');
sub bm_subfield {
    my ( $subfields, $path ) = @_;
    my $bm_path = &parse_bm_path($path);
    my $regex   = $bm_path->{subfield};

    my @results = ();

    for ( my $i = 0; $i < @$subfields; $i += 2 ) {
        my $code = $subfields->[$i];
        my $val  = $subfields->[ $i + 1 ];
        push( @results, $val ) if $code =~ /$regex/;
    }
    return \@results;
}

1;

=head1 NAME

Catmandu::Fix::bm_map - copy mab values of one field to a new field

=head1 SYNOPSIS

    # Copy all 245 subfields into the dc.title hash
    bm_map('245','dc.title');

    # Copy the 245-$a$b$c subfields into the dc.title hash
    bm_map('245abc','dc.title');

    # Copy the 651 subfields into the dc.subjects array
    bm_map('651','dc.subjects.$append');

    # Copy all the aar fields into a dc.date hash joining them by '; '
    bm_map('aar','dc.date', -join => ' - ');
    
    # Copy characters form field into the dc.date hash
    bm_map('012e/0-4','dc.date');

=cut
