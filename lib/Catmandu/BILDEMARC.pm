package Catmandu::BILDEMARC;

use v5.12;

use utf8;
use strict;
use warnings; 
use warnings    qw< FATAL  utf8     >;
use feature     qw< unicode_strings >;
use Carp        qw< carp croak confess cluck >;
use XML::LibXML::Reader;

=head1 NAME

Catmandu::BILDEMARC - Catmandu modules for working with BILDEMARC data.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 MODULES

=over

=item * L<Catmandu::BILDEMARC>

=item * L<Catmandu::Importer::BILDEMARC>

=item * L<Catmandu::Fix::bm_map>

=back

=head1 SYNOPSIS


L<Catmandu::BILDEMARC> is a parser for BILDEMARC XML records. 

    use Catmandu::BILDEMARC;

    my $parser = Catmandu::BILDEMARC->new( $filename );

    while ( my $record_hash = $parser->next() ) {
        # do something        
    }


=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my $file  = shift;

    my $self = {
        filename    => undef,
        rec_number  => 0,
        xml_reader  => undef,
    };

    # check for file or filehandle
    my $ishandle = eval { fileno($file); };
    if ( !$@ && defined $ishandle ) {
        my $reader = XML::LibXML::Reader->new(IO => $file)
             or croak "cannot read from filehandle $file\n";
        $self->{filename}   = scalar $file;
        $self->{xml_reader} = $reader;
    }
    elsif ( -e $file ) {
        my $reader = XML::LibXML::Reader->new(location => $file)
             or croak "cannot read from file $file\n";
        $self->{filename}   = $file;
        $self->{xml_reader} = $reader;
    }  
    else {
        croak "file or filehande $file does not exists";
    }
    return ( bless $self, $class );
}

=head2 next()

Reads the next record from XML input stream. Returns a Perl hash.

=cut

sub next {
    my $self = shift;
    if ( $self->{xml_reader}->nextElement( 'marc' ) ) {
        $self->{rec_number}++;
        my $id = $self->{xml_reader}->getAttribute('id');
        return {_id => $id, record =>  _decode( $self->{xml_reader} )};
    } 
    return;
}

=head2 _decode()

Deserialize a BILDEMARC record to an array of field arrays.

=cut

sub _decode {
    my $reader = shift;
    my @record;
    # get all field nodes from BILDEMARC record;
    foreach my $field_node ( $reader->copyCurrentNode(1)->getChildrenByTagName('*') ) {
        my @field;
        # get field tag number
        if ( $field_node->nodeName =~ m/((\d{3})|(\w{3}))$/ ) {
            my $tag = $1;
            # set field tag, separator, empty data field
            push(@field, ($tag, '_', ''));
            
            # get all subfield nodes
            foreach my $subfield_node ( $field_node->getChildrenByTagName('*') ) {
                if ( $subfield_node->nodeName =~ m/(\D{1,3})$/ ){
                    my $subfield_code = $1;
                    my $subfield_data = $subfield_node->textContent;
                    push(@field, ($subfield_code, $subfield_data));
                }               
                else{
                    croak "not a valid subfield code: $subfield_node->nodeName";
                }
            }
        }
        else{
            croak "not a valid field tag: $field_node->nodeName";
        }
        push(@record, [@field]);
    };
    return \@record;
}


=head1 AUTHOR

Johann Rolschewski, C<< <rolschewski at gmail.com> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catmandu::BILDEMARC

You can also look for information at:

    Catmandu
        https://metacpan.org/module/Catmandu::Introduction
        https://metacpan.org/search?q=Catmandu

    LibreCat
        http://librecat.org/tutorial/index.html

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Johann Rolschewski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Catmandu::BILDEMARC
