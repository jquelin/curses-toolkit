#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);
main() unless caller;

sub main {

	use POE::Component::Curses;

	use Curses::Toolkit::Widget::Window;
	use Curses::Toolkit::Widget::VBox;
	use Curses::Toolkit::Widget::HBox;
	use Curses::Toolkit::Widget::Button;
	use Curses::Toolkit::Widget::Border;

	use Curses::Toolkit::Widget::Label;

	my $root = POE::Component::Curses->spawn();

	local $| = 1;
	print STDERR "\n\n\n--- starting demo9 -----------------\n\n";

	$root->add_window(
        Curses::Toolkit::Widget::Window->new()
		  ->set_title('demo 14')
          ->add_widget(
            Curses::Toolkit::Widget::VBox->new()
              ->pack_end(
 			    Curses::Toolkit::Widget::HBox->new()
 				  ->pack_end(
			        my $button01 = Curses::Toolkit::Widget::Button
					  ->new_with_label('This is a button !')
				      ->set_name('button1'),
				    { expand => 1 }
  				  )
 				  ->pack_end(
 			        my $button02 = Curses::Toolkit::Widget::Button
 				      ->new_with_label('This is another button !')
 				      ->set_name('button2'),
				    { expand => 1 }
 				  ),
				  { expand => 0 }
			  )
              ->pack_end(
                Curses::Toolkit::Widget::Border->new()
                  ->add_widget(
                    Curses::Toolkit::Widget::Label->new()
                      ->set_text('expanding border with a label (this text) in it')
					),
				{ expand => 1 }
			  )
              ->pack_end(
 			    Curses::Toolkit::Widget::HBox->new()
 				  ->pack_end(
			        my $button1 = Curses::Toolkit::Widget::Button
				      ->new_with_label('This button is there!')
				      ->set_name('button1'),
				    { expand => 0 }
  				  )
				  ->pack_end(
 			        my $button2 = Curses::Toolkit::Widget::Button
 				      ->new_with_label('Yet Another Button !')
 				      ->set_name('button2'),
				    { expand => 0 }
 				  ),
				  { expand => 0 }
			  )
		  )
          ->set_coordinates(x1 => 0,   y1 => 0,
                            x2 => '100%',
							y2 => '100%',
						   )
      );
	$button1->set_focus(1);
#	$button1->register_event( type => keyboard

#$root
#      ->render()
#      ->display();
#sleep 5;
	POE::Kernel->run();
}

