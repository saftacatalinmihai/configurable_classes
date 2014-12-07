#!/usr/bin/env perl
#===============================================================================
#
#         FILE: MetaItemFactory.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 12/06/2014 03:42:17 PM
#     REVISION: ---
#===============================================================================

package MetaItemFactory;
use 5.14.1;
use strict;
use warnings;
use Data::Printer;
use Moose;
use namespace::autoclean;
use Class::MOP;

has configuration => (is => 'rw', default => sub { {} });
has _meta_item_factory => (is => 'rw');
has _meta_item_classes => (is => 'rw', default => sub { {} });

sub BUILD {
	my ($self, $configuration) = @_;	
	$self->_build__meta_item_factory($configuration);
}

sub get_factory {
	my $self = shift;
	return $self->_meta_item_factory->new_object();
}

sub _build__meta_item_factory {
	my ( $self, $configuration) = @_;

	my $meta_item_factory = Class::MOP::Class->create("ItemFactory");

	for my $type (keys %{$configuration}){
		my $meta_item_class = $self->_build_type_meta_class($type, $configuration);

		$meta_item_factory->add_method(
			"get_$type\_object" => sub {
				my ($self, @args) = @_;
				return $meta_item_class->new_object(@args);
			}
		);
	}

	$self->_meta_item_factory($meta_item_factory);
}

sub _build_type_meta_class {
	my ($self, $type, $configuration) = @_;
	my $meta_item_class = Class::MOP::Class->create($type);
	my @entity_attrs = @{$configuration->{$type}->{'attributes'}};

	for my $attr (@entity_attrs){
		$meta_item_class->add_attribute(
			Class::MOP::Attribute->new(
				$attr => (
					accessor => $attr,
					predicate => "has_$attr",
				)
			)
		);
	}

	if (defined $configuration->{$type}->{'relates_to'}) {
		for my $related_entity (keys %{$configuration->{$type}->{'relates_to'}}) {
			$meta_item_class->add_attribute(
				Class::MOP::Attribute->new(
					$related_entity => (
						accessor => $related_entity,
						predicate => "is_related_to_$related_entity",
					)
				)
			);
		}
	}

	$self->_meta_item_classes->{$type} = $meta_item_class;
	return $meta_item_class;
}

__PACKAGE__->meta->make_immutable;
1;

package TestMetaItemFactory;
use strict;
use warnings;
use Data::Printer;

my $conf = {
	type1 => {
		attributes => ['uid', 'name', 'parent', 'description'],
		relates_to => {
			type2 => 'one_to_many',
			type3 => 'one_to_one',
		},
	},
	type2 => {
		attributes => ['uid', 'name', 'parent', 'description'],
		relates_to => {
			type1 => 'many_to_one',
		},
	},
	type3 => {
		attributes => ['uid', 'name', 'parent', 'description'],
		relates_to => {
			type1 => 'one_to_one',
		},
	},
};

my $f_meta = MetaItemFactory->new($conf);
my $factory = $f_meta->get_factory();

my $t11 = $factory->get_type1_object(uid => 't11', name => 'name1', parent => 'root', description => 'description1');
my $t12 = $factory->get_type1_object(uid => 't12', name => 'name2', parent => $t11, description => 'description2');
my $t13 = $factory->get_type1_object(uid => 't13', name => 'name3', parent => $t12, description => 'description3');
p $t11;
p $t12;
p $t13;

my $t21 = $factory->get_type2_object(uid => 't21', name => 'name4', parent => 'root', description => 'description5');
my $t31 = $factory->get_type3_object(uid => 't31', name => 'name5', parent => 'root', type1 => $t11);

p $t21;
p $t31;
