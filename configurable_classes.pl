#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: met.pl
#
#        USAGE: ./met.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Mihai Safta
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 12/06/2014 01:07:06 PM
#     REVISION: ---
#===============================================================================

use 5.14.1;
use strict;
use warnings;
{
	package ItemFactory;
	use Moose;
	use Class::MOP;
	use Data::Printer;

	has metaclasses => ( is => "rw", default => sub { {} } );

	sub BUILD{
		my $self = shift;

		my $classes_configuration = {
			type1 => {
				name => "str",
				description => "str",
			},
			type2 => {
				name => "str",
				some_attribute => "int",
			}
		};

		for my $entity_type (keys %{$classes_configuration}) {
			my $entity_attrs = $classes_configuration->{$entity_type};
			$self->metaclasses->{$entity_type} = Class::MOP::Class->create(
				$entity_type => (
					methods => {
						get_name => sub { 
							my $self = shift; 
							return $self->{name};
						}
					}
				)
			);
			for my $attr (keys %{$entity_attrs}){
				$self->metaclasses->{$entity_type}->add_attribute(
					Class::MOP::Attribute->new($attr)
				);
			}
		}
	}

	sub get_new_object {
		my ($self, $type, @attrs) = @_;
		if ( defined $self->metaclasses->{$type} ) {
			return $self->metaclasses->{$type}->new_object(@attrs);
		}
		return;
	}

}

use Data::Printer;
use utf8;

my $factory = ItemFactory->new();
p $factory->get_new_object('type1', { name => 'item_name', description => 'item description'} );
