package Device::ParallelPort::JayCar;
use strict;
use Carp;
use Device::ParallelPort;
our $VERSION = "0.02";

=head1 NAME

Device::ParallelPort::JayCarXXX - Jaycar controlling device.

XXX This is all wrong - need to update...

=head1 SYNOPSIS

This is an example driver for a fairly common (in Australia anyway) parallel
port controller card. It can be used for real, but has been written in an easy
to read manner to allow it to be a base class for future drivers.

=head1 DESCRIPTION

To come.

=head1 NOTE ON NAMING

A note on class locations. If you are writting a general controller, eg: for a
high speed neon sign controller. Then you would always write that in its own
class (see CPAN for the best base class to put that in). Thats because more
than likely the sign supports multiple protocols such as Parallel, RS485, USB
and more. Then the propert place would be:

	SomeBaseClass::MySign::drv::ParallelPort

or simular. When you write a network class that talks TCPIP only for that sign,
you do not put it in the Net:: location, same for parallel port.

=head1 NOTE ON INHERITENCE

Should examples such

=head1 QUESTIONS

How to handle errors, when writting to the port?

=head1 AUTHOR

Scott Penrose L<scottp@dd.com.au>, L<http://linux.dd.com.au/>

=head1 SEE ALSO

L<Device::ParallelPort>

=cut

# How many relays (allows you to sub class and add more)
sub RELAYS { 8 };

# Need: Parallel Port and Board ID
# Return: Object
sub new {
	my ($class, $parport, $boardid) = @_;
	my $this = bless {}, ref($class) || $class;
	$this->init($parport, $boardid);
	return $this;
}

sub init {
	my ($this, $parport, $boardid) = @_;
	if (ref($parport)) {
		$this->{PARPORT} = $parport;
	} elsif (defined($parport)) {
		$this->{PARPORT} = Device::ParallelPort->new($parport)
			or croak("Unable to create ParPort Device");
	} else {
		croak "Invalid parport provided";
	}
	$this->{BOARDID} = $boardid || "0";

	$this->{RELAYS} = [];
	for (my $i = 0; $i < $this->RELAYS(); $i++) {
		$this->{RELAYS}[$i] = 0;
	}
}

sub _parport {
	my ($this) = @_;
	return $this->{PARPORT};
}

# Need: Relay Number (0-7)
# Return: True/False
# How: Must remember, can not get it from the board.
sub get {
	my ($this, $id) = @_;
	$this->_checkid($id);
	return $this->{RELAYS}[$id];
}

sub _checkid {
	my ($this, $id) = @_;
	if ($id < 0 || $id > $this->RELAYS) {
		croak "Invalid relay id specified - $id";
	}
}

# Need: Ralay Number (0-7) (optionally delay update)
# Return: NA
# How: Update memory map bit, set whole byte, flash with Board ID
sub on {
	my ($this, $id, $delay) = @_;
	$this->_checkid($id);
	$this->{RELAY}[$id] = 1;
	$this->update if (!defined($delay) || !$delay);
}

# See relay_on
sub off {
	my ($this, $id, $delay) = @_;
	$this->_checkid($id);
	$this->{RELAY}[$id] = 0;
	$this->update if (!defined($delay) || !$delay);
}

# Update the device.
# Need: NA
# Return: NA
# How: Use parport to update byte and then flash it.
sub update {
	my ($this) = @_;
	$this->_parport->set_byte(0, $this->_byte_calc);# Set the bit for this light
	$this->_parport->set_byte(2, 11);           	# Flash the address on then off
	$this->_parport->set_byte(2, 10);		# XXX This should be using real address
}

# Add bits together and return as integer.
# Need: NA (uses stored data)
# Return: Integer representing byte
# How: Add bits together as a byte (only those turned on)
sub _byte_calc {
        my ($this) = @_;
        my $ret = 0;
        for (my $i = 0; $i < $this->RELAYS; $i++) {
		if ($this->{RELAY}[$i]) {
			$ret = $ret + (1 << $i);
		}
        }
        return $ret;
}

1;
