require_relative '../aji'

featured_by_title = %w(Comedy News Games Sports Trailers Music Entertainment Film Tech Education Travel Howto Autos )
Aji::Category.set_featured featured_by_title

featured_by_title = %w( NowComedy NowNews NowPopular freddiew )
Aji::Channel.set_featured featured_by_title
