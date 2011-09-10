require_relative '../aji'

featured_by_title = %w(Comedy Music News Games Sports Trailers Entertainment Tech Film Education Travel Howto Autos )
Aji::Category.set_featured featured_by_title

featured_by_title = %w( NowPopular NowComedy NowNews aplusk freddiew )
Aji::Channel.set_featured featured_by_title
