import 'package:equatable/equatable.dart';

/// User's favourite selections for their profile
class ProfileFavourites extends Equatable {
  final String? athlete;
  final String? food;
  final String? sport;
  final String? tvShow;
  final String? actor;
  final String? singer;
  final String? movie;
  final String? book;
  final String? hobby;
  final String? travelDestination;

  const ProfileFavourites({
    this.athlete,
    this.food,
    this.sport,
    this.tvShow,
    this.actor,
    this.singer,
    this.movie,
    this.book,
    this.hobby,
    this.travelDestination,
  });

  ProfileFavourites copyWith({
    String? athlete,
    String? food,
    String? sport,
    String? tvShow,
    String? actor,
    String? singer,
    String? movie,
    String? book,
    String? hobby,
    String? travelDestination,
    bool clearAthlete = false,
    bool clearFood = false,
    bool clearSport = false,
    bool clearTvShow = false,
    bool clearActor = false,
    bool clearSinger = false,
    bool clearMovie = false,
    bool clearBook = false,
    bool clearHobby = false,
    bool clearTravelDestination = false,
  }) {
    return ProfileFavourites(
      athlete: clearAthlete ? null : (athlete ?? this.athlete),
      food: clearFood ? null : (food ?? this.food),
      sport: clearSport ? null : (sport ?? this.sport),
      tvShow: clearTvShow ? null : (tvShow ?? this.tvShow),
      actor: clearActor ? null : (actor ?? this.actor),
      singer: clearSinger ? null : (singer ?? this.singer),
      movie: clearMovie ? null : (movie ?? this.movie),
      book: clearBook ? null : (book ?? this.book),
      hobby: clearHobby ? null : (hobby ?? this.hobby),
      travelDestination: clearTravelDestination
          ? null
          : (travelDestination ?? this.travelDestination),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (athlete != null) 'athlete': athlete,
      if (food != null) 'food': food,
      if (sport != null) 'sport': sport,
      if (tvShow != null) 'tvShow': tvShow,
      if (actor != null) 'actor': actor,
      if (singer != null) 'singer': singer,
      if (movie != null) 'movie': movie,
      if (book != null) 'book': book,
      if (hobby != null) 'hobby': hobby,
      if (travelDestination != null) 'travelDestination': travelDestination,
    };
  }

  factory ProfileFavourites.fromJson(Map<String, dynamic> json) {
    return ProfileFavourites(
      athlete: json['athlete'] as String?,
      food: json['food'] as String?,
      sport: json['sport'] as String?,
      tvShow: json['tvShow'] as String?,
      actor: json['actor'] as String?,
      singer: json['singer'] as String?,
      movie: json['movie'] as String?,
      book: json['book'] as String?,
      hobby: json['hobby'] as String?,
      travelDestination: json['travelDestination'] as String?,
    );
  }

  /// Check if any favourites are set
  bool get hasAnyFavourites =>
      athlete != null ||
      food != null ||
      sport != null ||
      tvShow != null ||
      actor != null ||
      singer != null ||
      movie != null ||
      book != null ||
      hobby != null ||
      travelDestination != null;

  /// Count of filled favourites
  int get filledCount {
    int count = 0;
    if (athlete != null) count++;
    if (food != null) count++;
    if (sport != null) count++;
    if (tvShow != null) count++;
    if (actor != null) count++;
    if (singer != null) count++;
    if (movie != null) count++;
    if (book != null) count++;
    if (hobby != null) count++;
    if (travelDestination != null) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        athlete,
        food,
        sport,
        tvShow,
        actor,
        singer,
        movie,
        book,
        hobby,
        travelDestination,
      ];
}

/// Curated lists of popular options for favourites
class FavouritesOptions {
  // Top 50 Athletes (Most followed/recognized)
  static const List<String> athletes = [
    'Cristiano Ronaldo',
    'Lionel Messi',
    'LeBron James',
    'Neymar Jr',
    'Virat Kohli',
    'Roger Federer',
    'Serena Williams',
    'Tom Brady',
    'Kylian Mbappé',
    'Stephen Curry',
    'Rafael Nadal',
    'Novak Djokovic',
    'Usain Bolt',
    'Michael Jordan',
    'Tiger Woods',
    'Lewis Hamilton',
    'Conor McGregor',
    'David Beckham',
    'Sachin Tendulkar',
    'MS Dhoni',
    'Michael Phelps',
    'Simone Biles',
    'Naomi Osaka',
    'Kobe Bryant',
    'Shaquille O\'Neal',
    'Floyd Mayweather',
    'Manny Pacquiao',
    'Wayne Gretzky',
    'Muhammad Ali',
    'Mike Tyson',
    'Pelé',
    'Diego Maradona',
    'Zlatan Ibrahimović',
    'Kevin Durant',
    'Aaron Rodgers',
    'Patrick Mahomes',
    'Giannis Antetokounmpo',
    'Luka Dončić',
    'Erling Haaland',
    'Mohamed Salah',
    'Robert Lewandowski',
    'Karim Benzema',
    'Max Verstappen',
    'Rory McIlroy',
    'Phil Mickelson',
    'Derek Jeter',
    'Shohei Ohtani',
    'Canelo Álvarez',
    'Jon Jones',
    'Israel Adesanya',
  ];

  // Top 20 Foods
  static const List<String> foods = [
    'Pizza',
    'Sushi',
    'Tacos',
    'Pasta',
    'Burger',
    'Biryani',
    'Ramen',
    'Steak',
    'Pad Thai',
    'Fried Chicken',
    'Dim Sum',
    'Kebab',
    'Fish & Chips',
    'Paella',
    'Pho',
    'Curry',
    'BBQ Ribs',
    'Falafel',
    'Ceviche',
    'Peking Duck',
  ];

  // Top 20 Sports
  static const List<String> sports = [
    'Football (Soccer)',
    'Cricket',
    'Basketball',
    'Tennis',
    'American Football',
    'Baseball',
    'Hockey',
    'Golf',
    'Rugby',
    'Boxing',
    'MMA / UFC',
    'Formula 1',
    'Swimming',
    'Athletics',
    'Volleyball',
    'Table Tennis',
    'Badminton',
    'Cycling',
    'Gymnastics',
    'Skiing',
  ];

  // Top TV Shows (Most watched/highest rated)
  static const List<String> tvShows = [
    'Friends',
    'Game of Thrones',
    'Breaking Bad',
    'The Office',
    'Stranger Things',
    'The Crown',
    'Money Heist',
    'Squid Game',
    'The Mandalorian',
    'The Witcher',
    'Peaky Blinders',
    'Narcos',
    'The Sopranos',
    'The Wire',
    'Sherlock',
    'Black Mirror',
    'Dark',
    'Better Call Saul',
    'House of the Dragon',
    'Wednesday',
    'The Last of Us',
    'Succession',
    'Ted Lasso',
    'Euphoria',
    'The Bear',
  ];

  // Top Actors
  static const List<String> actors = [
    'Leonardo DiCaprio',
    'Tom Hanks',
    'Dwayne Johnson',
    'Robert Downey Jr.',
    'Chris Hemsworth',
    'Ryan Reynolds',
    'Brad Pitt',
    'Johnny Depp',
    'Will Smith',
    'Tom Cruise',
    'Keanu Reeves',
    'Morgan Freeman',
    'Denzel Washington',
    'Samuel L. Jackson',
    'Chris Evans',
    'Margot Robbie',
    'Scarlett Johansson',
    'Jennifer Lawrence',
    'Emma Stone',
    'Anne Hathaway',
    'Zendaya',
    'Timothée Chalamet',
    'Shah Rukh Khan',
    'Priyanka Chopra',
    'Cate Blanchett',
  ];

  // Top Singers/Artists
  static const List<String> singers = [
    'Taylor Swift',
    'Drake',
    'Ed Sheeran',
    'The Weeknd',
    'Beyoncé',
    'Ariana Grande',
    'Billie Eilish',
    'Dua Lipa',
    'Justin Bieber',
    'Rihanna',
    'Eminem',
    'Kanye West',
    'Post Malone',
    'Bruno Mars',
    'Lady Gaga',
    'Adele',
    'Shakira',
    'Bad Bunny',
    'BTS',
    'BLACKPINK',
    'Harry Styles',
    'Doja Cat',
    'Kendrick Lamar',
    'Travis Scott',
    'SZA',
  ];

  // Top Movies
  static const List<String> movies = [
    'The Shawshank Redemption',
    'The Godfather',
    'Inception',
    'The Dark Knight',
    'Pulp Fiction',
    'Forrest Gump',
    'Interstellar',
    'Fight Club',
    'Titanic',
    'Avatar',
    'Avengers: Endgame',
    'The Matrix',
    'Gladiator',
    'Jurassic Park',
    'The Lion King',
    'Harry Potter Series',
    'Lord of the Rings',
    'Star Wars',
    'Oppenheimer',
    'Barbie',
  ];

  // Popular Books
  static const List<String> books = [
    'Harry Potter Series',
    'The Lord of the Rings',
    'The Alchemist',
    '1984',
    'To Kill a Mockingbird',
    'Pride and Prejudice',
    'The Great Gatsby',
    'The Catcher in the Rye',
    'The Hunger Games',
    'Atomic Habits',
    'Rich Dad Poor Dad',
    'Think and Grow Rich',
    'The Psychology of Money',
    'Sapiens',
    'The Subtle Art of Not Giving a F*ck',
  ];

  // Popular Hobbies
  static const List<String> hobbies = [
    'Traveling',
    'Photography',
    'Gaming',
    'Cooking',
    'Reading',
    'Fitness',
    'Music',
    'Hiking',
    'Dancing',
    'Painting',
    'Yoga',
    'Gardening',
    'Cycling',
    'Swimming',
    'Movies',
  ];

  // Popular Travel Destinations
  static const List<String> travelDestinations = [
    'Paris, France',
    'Tokyo, Japan',
    'New York, USA',
    'Bali, Indonesia',
    'Dubai, UAE',
    'London, UK',
    'Rome, Italy',
    'Barcelona, Spain',
    'Maldives',
    'Santorini, Greece',
    'Bangkok, Thailand',
    'Sydney, Australia',
    'Amsterdam, Netherlands',
    'Istanbul, Turkey',
    'Singapore',
  ];
}
