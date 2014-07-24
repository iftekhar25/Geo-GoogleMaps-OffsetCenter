use strict;
use warnings;
package Geo::GoogleMaps::OffsetCenter;

use Math::Trig qw/ deg2rad rad2deg pi /;
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

