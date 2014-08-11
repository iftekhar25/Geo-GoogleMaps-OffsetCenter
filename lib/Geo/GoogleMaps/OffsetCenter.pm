use strict;
use warnings;
our $VERSION = '0.01';
package Geo::GoogleMaps::OffsetCenter;
# ABSTRACT: Offset a Lat/Long to account for an occlusion over your map area

use Params::Validate;
use Regexp::Common;
use Exporter::Easy (
    OK => [ qw/ offset_google_maps_center / ],
);

use constant RADIUS_OF_EARTH => 6_378_100;

sub offset_google_maps_center {
    validate_pos(
        @_,
        { regex => qr/$RE{num}{real}/, optional => 0 }, # latitude
        { regex => qr/$RE{num}{real}/, optional => 0 }, # longitude
        { regex => qr/$RE{num}{int}/,  optional => 0 }, # width
        { regex => qr/$RE{num}{int}/,  optional => 0 }, # height
        { regex => qr/$RE{num}{int}/,  optional => 0 }, # zoom level
        { regex => qr/$RE{num}{int}/,  optional => 0 }, # occlusion
    );

    my(
        $latitude_geo_entity,
        $longitude_geo_entity,
        $width_total,
        $height_total,
        $zoom_level,
        $width_occlusion_from_left
    ) = @_;

    # we will need these
    my $number_of_pixels  = 256 * 2**$zoom_level;
    my $meters_per_pixel  = ( 2 * pi * RADIUS_OF_EARTH ) / $number_of_pixels;
    my $meters_per_degree = ( 2 * pi * RADIUS_OF_EARTH ) / 360;

    # find the number of pixels we need to move the center
    my $pixels_offset = _get_pixels_offset( $width_total, $height_total, $width_occlusion_from_left );

    # find the number of meters we need to move
    my $meters_offset = $pixels_offset * $meters_per_pixel;

    # now find the number of degrees we need to move
    my $degrees_offset = $meters_offset / $meters_per_degree;

    $longitude_geo_entity -= $degrees_offset;

    return {
        latitude  => $latitude_geo_entity,
        longitude => $longitude_geo_entity
    };
}


sub _get_pixels_offset {
    my( $width_total, $height_total, $width_occlusion_from_left ) = @_;

    # actually we don't care about the height, heh.

    my $current_center = int( $width_total / 2 );
    my $center_of_effective_area = int( $width_total - $width_occlusion_from_left ) / 2;

    return abs( $current_center - $center_of_effective_area );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::GoogleMaps::OffsetCenter - Offset a Lat/Long to account for an occlusion over your map area

=head1 VERSION

 version 0.01

=head1 SYNOPSIS

 use Geo::GoogleMaps::OffsetCenter qw/ offset_google_maps_center /;

 my $new_lat_long = offset_google_maps_center(
    52.3728, # latitude
    4.8930,  # longitude
    800,     # width
    400,     # height
    16,      # Google Maps zoom level
    200      # left-bound width of the occlusion
 );

=head1 DESCRIPTION

Consider the following situation:

 A
 +-----------------------------------------------------+
 | +-----------------------+B                          |
 | |                       |                           |
 | |  Lorem ipsum          |                           |
 | |                       |           Map Area        |
 | |                       |                           |
 | |                       |                           |
 | |                       |                           |
 | +-----------------------+                           |
 +-----------------------------------------------------+

Box A is your full map area, and box B is an overlay containing text. Box B is
considered the occlusion in this case.

This means the effective map area is the region to the right. Maybe your
overlay is transparent, maybe it doesn't cover the enclosing map area
edge-to-edge, so you need map tiles to be displayed under the occlusion, but
you want a point-of-interest (specified by a latitude and a longitude) to be
centered on your effective map area, the smaller area to the right.

This module will allow you to do an offset of a given latitude/longitude, given
the width of your original box, and the left-bound width of your occlusion.

=head1 METHODS

=over 4

=item I<offset_google_maps_center>

=over 8

=item 1. latitude_geo_entity

A valid latitude, basically a floating point number.

=item 2. longitude_geo_entity

A valid longitude, same as above.

=item 3. width_total

The total width of the map you want rendered. This includes the occluded area,
although it is partially or wholly occluded, you will need a rendering of a map
in this area.

=item 4. height_total

Height is currently ignored, height offset has not been integrated here.

=item 5. zoom_level

A Google Maps zoom-level, basicaly 0 .. 21.

See L<Google Maps Documentation|https://developers.google.com/maps/documentation/staticmaps/#Zoomlevels>.

=item 6. width_occlusion_from_left

The occluded area must be specified as left-bound, which means the offset is
always towards the right. This is a known limitation. This should always be
less than the total area of the maps displayed. Otherwise you're just being
silly.

=back

=back

=head1 LIMITATIONS

=over 4

=item *

Currently, occlusions are only to be left-bound

=item *

There is no latitude offset, your location will now be offset by longitude
only, i.e., from the west, heading east

=back

=head1 ACKNOWLEDGEMENT

This module was originally developed for use at Booking.com, and was
genericized and published on CPAN with their permission, for which the author
would like to express his gratitude.

=cut

