package Curses::Toolkit::Widget::VPaned;

use warnings;
use strict;

use parent qw(Curses::Toolkit::Widget::Paned);

use Params::Validate qw(:all);

=head1 NAME

Curses::Toolkit::Widget::VPane - a container with two panes arranged vertically

=head1 DESCRIPTION

This widget contain 2 widgets. The children are packed vertically.

=cut

=head1 CONSTRUCTOR

=head2 new

  input : none
  output : a Curses::Toolkit::Widget::VPaned

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	return $self;
}

sub _mouse_conditional_code {
	my ($self, $ec, $wc) = @_;
	$ec->x1() >= $wc->x1() + $gp
	  && $ec->x1() < $wc->x1() + $gp + $gw
		&& $ec->y1() < $wc->y2()
}


package Curses::Toolkit::Widget::HPane;

use warnings;
use strict;

use parent qw(Curses::Toolkit::Widget::Pane);

use Params::Validate qw(:all);

=head1 NAME

Curses::Toolkit::Widget::HPane - a container with two panes arranged horizontally

=head1 DESCRIPTION

This widget contain 2 widgets. The children are packed horizontally.

=cut

=head1 CONSTRUCTOR

=head2 new

  input : none
  output : a Curses::Toolkit::Widget::HPane

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	# default position
	$self->set_gutter_position(0);

	# listen to the Mouse for moving the gutter
	$self->add_event_listener(
		Curses::Toolkit::EventListener->new(
			accepted_event_class => 'Curses::Toolkit::Event::Mouse::Click',
			conditional_code => sub { 
				my ($event) = @_;
				$event->{button} eq 'button1' or return 0;
				$self->{_gutter_move_pressed} && $event->{type} eq 'released'
				  and return 1;
				my $c = $event->{coordinates};
				my $wc = $self->get_coordinates();
				my $gp = $self->get_gutter_position();
				#	my $gw = $self->get_theme_property('gutter_width');
				my $gw = 1;
				! $self->{_gutter_move_pressed}
				&& $event->{type} eq 'pressed'
				&& $c->x1() >= $wc->x1() + $gp
				&& $c->x1() < $wc->x1() + $gp + $gw
				&& $c->y1() < $wc->y2()
				  and return 1;
				return 0;
			},
			code => sub {
				my ($event, $widget) = @_;

				if ($self->{_gutter_move_pressed}) {
					# means we released it
					$self->unset_modal();
					my $c = $event->{coordinates};
					my $wc = $self->get_coordinates();
					$self->set_gutter_position($c->x1() - $wc->x1() );
					$self->_rebuild_children_coordinates();
					$self->needs_redraw();
					$self->{_gutter_move_pressed} = 0;
				} else {
					# means we pressed it
					$self->set_modal();
					$self->needs_redraw();
					$self->{_gutter_move_pressed} = 1;					
				}
				return;
			},
		)
	);

	return $self;
}

=head1 METHODS

=head2 add1

Add a widget in the left box

  input  : the child widget
  output : the current widget (not the child widget)

=cut

sub add1 {
	my $self = shift;
    my ($child_widget) = validate_pos( @_,
									   { isa => 'Curses::Toolkit::Widget' },
									 );
	defined $self->{child1} and die "there is already a child 1";
	$self->_add_child_at_beginning($child_widget);
	$self->{child1} = $child_widget;
	$child_widget->_set_parent($self);
	$self->rebuild_all_coordinates();
	return $self;
}

=head2 add1

Add a widget in the right box

  input  : the child widget
  output : the current widget (not the child widget)

=cut

sub add2 {
	my $self = shift;
    my ($child_widget) = validate_pos( @_,
									   { isa => 'Curses::Toolkit::Widget' },
									 );
	defined $self->{child2} and die "there is already a child 2";
	$self->_add_child_at_end($child_widget);
	$self->{child2} = $child_widget;
	$child_widget->_set_parent($self);
	$self->rebuild_all_coordinates();
	return $self;
}

=head2 set_gutter_position

Set the position of the gutter from the left

  input  : the position (an integer)
  output : the current widget (not the child widget)

=cut

sub set_gutter_position {
	my $self = shift;
	my ($position) = validate_pos( @_,
								   { type => SCALAR,
								   },
								 );
	$position < 0 and $position = 0;
	$self->_del_actual_gutter_position();
	$self->{position} = $position;
	
	return $self;
}

# sets the gutter position, which can be different from the one desired
sub _set_actual_gutter_position {
	my ($self, $position) = @_;
	$position < 0 and $position = 0;
	$self->{actual_position} = $position;
	return $self;
}

# deletes the actual gutter position
sub _del_actual_gutter_position {
	my ($self) = @_;
	$self->{actual_position} = undef;
	return $self;
}

=head2 get_gutter_position

Return the position of the gutter from the left

  input  : none
  output : the current gutter position

=cut

sub get_gutter_position {
	my ($self) = @_;
	defined $self->{actual_position}
	  and return $self->{actual_position};
	return $self->{position};
}

sub _get_original_gutter_position {
	my ($self) = @_;
	return $self->{position};
}

# =head2 set_gutter_size

# Set the width of the gutter

#   input  : the width (an integer)
#   output : the current widget (not the child widget)

# =cut

# sub set_gutter_size {
# 	my $self = shift;
# 	my ($size) = validate_pos( @_,
# 								   { type => SCALAR,
# 									 callbacks => { positive_integer => { shift() >= 0 } }
# 								   },
# 								 );
	
# }

sub _rebuild_children_coordinates {
	my ($self) = @_;
	my $available_space = $self->_get_available_space();
	my ($child1, $child2) = $self->get_children();

#	my $gw = $self->get_theme_property('gutter_width');
	my $gw = 1;
	my $gp = $self->_get_original_gutter_position();
	if ($gp > ($available_space->width() - $gw)) {
		$gp = $available_space->width() - $gw;
		$self->_set_actual_gutter_position($gp);
	} else {
		$self->_del_actual_gutter_position();
	}

	if (defined $child1) {
		my $child1_space = $available_space->clone();
		$child1_space->set( x2 => $child1_space->x1() + $gp );
		$child1->_set_relatives_coordinates($child1_space);
	}
	if (defined $child2) {
		my $child2_space = $available_space->clone();
		$child2_space->set( x1 => $child2_space->x1() + $gp + $gw );
		$child2->_set_relatives_coordinates($child2_space);
	}
	return $self;
}

=head2 get_desired_space

Given a coordinate representing the available space, returns the space desired

  input : a Curses::Toolkit::Object::Coordinates object
  output : a Curses::Toolkit::Object::Coordinates object

=cut

sub get_desired_space {
	my ($self, $available_space) = @_;
	my $desired_space = $available_space->clone();
	return $desired_space;
}

=head2 get_minimum_space

Given a coordinate representing the available space, returns the minimum space
needed to properly display itself

  input : a Curses::Toolkit::Object::Coordinates object
  output : a Curses::Toolkit::Object::Coordinates object

=cut

sub get_minimum_space {
	my ($self, $available_space) = @_;
	my ($child1, $child2) = $self->get_children();

#	my $gw = $self->get_theme_property('gutter_width');
	my $gw = 1;
	my $gp = $self->get_gutter_position();

	my $minimum_space = $available_space->clone();
	# if the gutter is places over the edge of the space
	if ($gp > ($available_space->width() - $gw)) {
		return $minimum_space
# 		$gp = $available_space->width() - $gw;
# 		$self->set_gutter_position($gp);
	}

# 	if (defined $child1) {
# 		my $child_available_space = $available_space->clone();
# 		$child_available_space->set( x2 => $available_space->x1() + $gp );
# 		$child_space = $child1->get_minimum_space($child_available_space);
# 	}


	$minimum_space = Curses::Toolkit::Object::Coordinates->new_zero();
	$minimum_space->set( x2 => $gp + $gw, y2 => 1 );
	if (defined $child2) {
		my $child_available_space = $available_space->clone();
		$child_available_space->set( x1 => $available_space->x1() + $gp + $gw );
		my $child_space = $child2->get_minimum_space($child_available_space);
		return $child_space;
	}
# 	$minimum_space->set( x2 => $available_space->x1() + $child_space->width() + 2 * $bw,
# 						 y2 => $available_space->y1() + $child_space->height() + 2 * $bw,
# 					   );
	return $minimum_space;
}

sub draw {
	my ($self) = @_;
	my $theme = $self->get_theme();

	my $attr = {};
	$self->{_gutter_move_pressed} and $attr->{clicked} = 1;

	my $c = $self->get_coordinates();
	my $gp = $self->get_gutter_position();
#	my $gw = $self->get_theme_property('gutter_width');
	my $gw = 1;
# 	if ($gp + $gw >= $c->x2()) {
# 		$gp = $c->x2() - $gw - 1;
# 		$self->_set_actual_gutter_position($gp);
# 	}
	$gw > 0 or return;
	for my $i (0..$gw-1) {
		$theme->draw_vline($c->x1() + $gp + $i, $c->y1(), $c->height(), $attr );
	}
	return;
}

1;