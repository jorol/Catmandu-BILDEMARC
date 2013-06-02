package Catmandu::Importer::BILDEMARC;

use Catmandu::Sane;
use Catmandu::BILDEMARC;
use Moo;

with 'Catmandu::Importer';

has type => ( is => 'ro', default => sub {'XML'} );

sub bildemarc_generator {
    my $self = shift;

    my $file;

    given ( $self->type ) {
        when ('XML') {
            $file = Catmandu::BILDEMARC->new( $self->fh );
        }
        die "unknown";
    }

    sub {
        my $record = $file->next();
        return unless $record;
        return $record;
    };
}

sub generator {
    my ($self) = @_;
    my $type = $self->type;

    given ($type) {
        when (/^XML$/) {
            return $self->bildemarc_generator;
        }
        die "need BILDEMARC XML data as input";
    }
}

=head1 NAME

Catmandu::Importer::BILDEMARC - Package that imports BILDEMARC XML data

=head1 SYNOPSIS

    use Catmandu::Importer::BILDEMARC;

    my $importer = Catmandu::Importer::BILDEMARC->new(file => "bildemarc.xml", type=> "XML");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 BILDEMARC

Parse BILDEMARC XML to native Perl hash containing two keys: '_id' and 'record'. 

 {
  'record' => [
                [
                  'aar',
                  '_',
                  '',
                  'fra',
                  '1898',
                  'til',
                  '1898'
                ],
                [
                  '012',
                  '_',
                  '',
                  'e',
                  '2002-04-27',
                  'k',
                  'IJGR'
                ],
                [
                  '245',
                  '_',
                  '',
                  'a',
                  "Folkemengde utenfor brannstasjonen og r\x{c3}\x{a5}dhuset i Kongens gate"
                ]
        ],
  '_id' => 'UBT-HO-016'
 } 

=head1 METHODS

=head2 new(file => $filename,type=>$type)

Create a new BILDEMARC importer for $filename. Use STDIN when no filename is given. Type 
describes the sytax of the BILDEMARC records. Currently we support: BILDEMARC.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::BILDEMARC methods are not idempotent: BILDEMARC feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
