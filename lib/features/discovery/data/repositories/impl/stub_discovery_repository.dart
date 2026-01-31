import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../discovery_repository.dart';

// ignore: unnecessary_const
/// Mock implementation of DiscoveryRepository with sample profiles.
/// This allows the app to function for development/demo without a backend.
class StubDiscoveryRepository implements DiscoveryRepository {
  static const _matchesKey = 'mock_matches';
  static const _swipedKey = 'mock_swiped';
  static const _likesKey =
      'mock_likes'; // Track who liked whom for mutual matching

  final _random = Random();

  // Sample mock profiles for discovery with location data for distance calculations
  // Note: Some profiles have isActive/createdAt to demonstrate Active/New here badges
  // ignore: unnecessary_const
  final List<Profile> _mockProfiles = [
    Profile(
      id: 'mock_1',
      name: 'Emma',
      age: 26,
      gender: 'Woman',
      dateOfBirth: DateTime(1998, 4, 12),
      bio:
          'Coffee entwhen husiast ☕ | Travel addict ✈️ | Dog mom 🐕\n\nLooking for someone to explore the city with!',
      photoUrls: const [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400'
      ],
      videoUrls: const [],
      interests: const ['Travel', 'Photography', 'Coffee', 'Hiking', 'Dogs'],
      profilePrompts: const [
        ProfilePrompt(
            questionId: 'perfect_date',
            answer:
                'A spontaneous road trip to a coastal town, followed by sunset drinks on the beach'),
        ProfilePrompt(
            questionId: 'never_shut_up',
            answer:
                'My travel adventures - I have way too many photos from my backpacking trips!'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7849, // San Francisco downtown
      longitude: -122.4094,
      distance: 5, // 5 km away
      distanceUnit: 'km',
      isVerified: true,
      isActive: true, // Currently online
      heightCm: 165,
      relationshipGoals: 'Long-term relationship',
      smoking: 'Never',
      drinking: 'Socially',
      languages: const ['English', 'Spanish'],
      zodiacSign: 'Leo',
      educationLevel: 'Bachelor\'s degree',
      jobTitle: 'Product Designer',
      company: 'Tech Startup',
      preferences: const DiscoveryPreferences(
          minAge: 24,
          maxAge: 35,
          maxDistanceKm: 50,
          showMeGenders: ['Man'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    Profile(
      id: 'mock_2',
      name: 'Aayush',
      age: 23,
      gender: 'Man',
      dateOfBirth: DateTime(2001, 1, 9),
      bio:
          'Software engineer by day, musician by night 🎸\n\nLet\'s grab tacos and talk about life.',
      photoUrls: const [
        'https://www.instagram.com/p/DO0vpy8DxHr/?igsh=NjcyOXlqYzU1NGdu'
      ],
      videoUrls: const [],
      interests: const ['Music', 'Coding', 'Tacos', 'Gaming', 'Fitness'],
      profilePrompts: const [
        ProfilePrompt(
            questionId: 'go_to_karaoke',
            answer: 'Bohemian Rhapsody - yes, I do all the parts'),
        ProfilePrompt(
            questionId: 'hot_take',
            answer: 'Pineapple belongs on pizza and I will die on this hill'),
        ProfilePrompt(
            questionId: 'typical_sunday',
            answer:
                'Coffee, coding side projects, and catching up on Formula 1'),
      ],
      country: 'Nepal',
      city: 'Pokhara',
      latitude: 37.7599, // Mission District
      longitude: -122.4148,
      distance: 8,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 183,
      relationshipGoals: 'Long-term relationship',
      languages: const ['English'],
      zodiacSign: 'Virgo',
      educationLevel: 'Master\'s degree',
      jobTitle: 'Software Engineer',
      company: 'Google',
      preferences: const DiscoveryPreferences(
          minAge: 23,
          maxAge: 32,
          maxDistanceKm: 50,
          showMeGenders: ['Woman'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    Profile(
      id: 'mock_3',
      name: 'Sofia',
      age: 24,
      gender: 'Woman',
      dateOfBirth: DateTime(2000, 7, 22),
      bio:
          'Med student 👩‍⚕️ | Foodie 🍕 | Netflix binger 📺\n\nSwipe right if you can handle my puns!',
      photoUrls: const [
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400'
      ],
      videoUrls: const [],
      interests: const ['Medicine', 'Cooking', 'Netflix', 'Yoga', 'Books'],
      country: 'United States',
      city: 'Los Angeles',
      latitude: 34.0522, // Los Angeles
      longitude: -118.2437,
      distance: 560, // Far away (LA to SF)
      distanceUnit: 'km',
      isVerified: false,
      createdAt: DateTime.now()
          .subtract(const Duration(days: 3)), // New user (3 days ago)
      heightCm: 160,
      relationshipGoals: 'Something casual',
      languages: const ['English', 'Portuguese'],
      zodiacSign: 'Pisces',
      educationLevel: 'Doctorate',
      jobTitle: 'Medical Student',
      school: 'UCLA',
      preferences: const DiscoveryPreferences(
          minAge: 24,
          maxAge: 34,
          maxDistanceKm: 30,
          showMeGenders: ['Man'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'Los Angeles'),
    ),
    const Profile(
      id: 'mock_4',
      name: 'Michael',
      age: 31,
      gender: 'Man',
      bio:
          'Architect who loves building things 🏗️\n\nWeekends = hiking + craft beer',
      photoUrls: [
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400'
      ],
      videoUrls: [],
      interests: [
        'Architecture',
        'Hiking',
        'Craft Beer',
        'Photography',
        'Design'
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7955, // Marina District
      longitude: -122.4362,
      distance: 12,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 180,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'German'],
      zodiacSign: 'Capricorn',
      educationLevel: 'Master\'s degree',
      jobTitle: 'Architect',
      company: 'Foster + Partners',
      preferences: DiscoveryPreferences(
          minAge: 25,
          maxAge: 35,
          maxDistanceKm: 40,
          showMeGenders: ['Woman'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_5',
      name: 'Olivia',
      age: 27,
      gender: 'Woman',
      bio:
          'Marketing guru 📈 | Yoga lover 🧘‍♀️ | Plant mom 🌱\n\nLooking for my adventure partner!',
      photoUrls: [
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400'
      ],
      videoUrls: [],
      interests: ['Marketing', 'Yoga', 'Plants', 'Sustainability', 'Wine'],
      country: 'United States',
      city: 'New York',
      latitude: 40.7128, // New York
      longitude: -74.0060,
      distance: 4100, // Cross-country
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 168,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'French'],
      zodiacSign: 'Libra',
      educationLevel: 'Bachelor\'s degree',
      jobTitle: 'Marketing Manager',
      company: 'Nike',
      preferences: DiscoveryPreferences(
          minAge: 26,
          maxAge: 36,
          maxDistanceKm: 25,
          showMeGenders: ['Man'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'New York'),
    ),
    const Profile(
      id: 'mock_6',
      name: 'Daniel',
      age: 28,
      gender: 'Man',
      bio:
          'Chef 👨‍🍳 | Foodie at heart | Will cook for you 🍳\n\nThe way to my heart is through good conversation.',
      photoUrls: [
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400'
      ],
      videoUrls: [],
      interests: ['Cooking', 'Food', 'Travel', 'Wine', 'Restaurants'],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.8044, // North Beach
      longitude: -122.4079,
      distance: 3,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 178,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'Italian'],
      zodiacSign: 'Taurus',
      educationLevel: 'Associate degree',
      jobTitle: 'Head Chef',
      company: 'Fine Dining Restaurant',
      preferences: DiscoveryPreferences(
          minAge: 23,
          maxAge: 33,
          maxDistanceKm: 35,
          showMeGenders: ['Woman'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_7',
      name: 'Ava',
      age: 25,
      gender: 'Woman',
      bio:
          'Artist 🎨 | Dreamer | Cat person 🐱\n\nLooking for someone who appreciates creativity.',
      photoUrls: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400'
      ],
      videoUrls: [],
      interests: ['Art', 'Painting', 'Museums', 'Cats', 'Music'],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7694, // Castro
      longitude: -122.4362,
      distance: 6,
      distanceUnit: 'km',
      isVerified: false,
      heightCm: 163,
      relationshipGoals: 'Still figuring it out',
      languages: ['English'],
      zodiacSign: 'Aquarius',
      educationLevel: 'Bachelor\'s degree',
      jobTitle: 'Freelance Artist',
      preferences: DiscoveryPreferences(
          minAge: 24,
          maxAge: 32,
          maxDistanceKm: 45,
          showMeGenders: ['Man', 'Woman'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_8',
      name: 'Noah',
      age: 30,
      gender: 'Man',
      bio:
          'Entrepreneur 🚀 | Fitness junkie 💪 | Dog dad\n\nBuilding companies and meaningful connections.',
      photoUrls: [
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400'
      ],
      videoUrls: [],
      interests: ['Startups', 'Fitness', 'Dogs', 'Investing', 'Podcasts'],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7864, // SOMA
      longitude: -122.3892,
      distance: 2,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 185,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'Mandarin'],
      zodiacSign: 'Aries',
      educationLevel: 'MBA',
      jobTitle: 'Founder & CEO',
      company: 'Tech Startup',
      preferences: DiscoveryPreferences(
          minAge: 25,
          maxAge: 35,
          maxDistanceKm: 50,
          showMeGenders: ['Woman'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_9',
      name: 'Isabella',
      age: 23,
      gender: 'Woman',
      bio:
          'Dance teacher 💃 | Sunset chaser 🌅 | Taco Tuesday enthusiast\n\nLife is short, dance more!',
      photoUrls: [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400'
      ],
      videoUrls: [],
      interests: ['Dancing', 'Fitness', 'Beach', 'Music', 'Tacos'],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'perfect_date',
            answer: 'Salsa dancing followed by late-night tacos on the beach'),
        ProfilePrompt(
            questionId: 'change_my_mind',
            answer: 'Dancing is the best form of exercise'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7599,
      longitude: -122.3894,
      distance: 4,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 162,
      relationshipGoals: 'Something casual',
      languages: ['English', 'Spanish'],
      zodiacSign: 'Sagittarius',
      educationLevel: "Bachelor's degree",
      jobTitle: 'Dance Instructor',
      company: 'DanceFit Studio',
      preferences: DiscoveryPreferences(
          minAge: 22,
          maxAge: 30,
          maxDistanceKm: 40,
          showMeGenders: ['Man'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_10',
      name: 'Niraj',
      age: 22,
      gender: 'Man',
      bio:
          'Physical therapist 🏥 | Rock climber 🧗 | Coffee snob ☕\n\nI can fix your back pain and your bad mood.',
      photoUrls: [
        'https://www.instagram.com/s/aGlnaGxpZ2h0OjE4MDYyNTg1NTU1MTE1MjY4?story_media_id=3587444512416620001&igsh=NXF2Mzl0bGp1aGNq'
      ],
      videoUrls: [],
      interests: [
        'Rock Climbing',
        'Fitness',
        'Coffee',
        'Outdoor Activities',
        'Health'
      ],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'hot_take',
            answer: 'Chiropractors are just expensive massage therapists'),
        ProfilePrompt(
            questionId: 'typical_sunday',
            answer:
                'Early morning climb at the gym, brunch, then meal prepping for the week'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7849,
      longitude: -122.4094,
      distance: 7,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 182,
      relationshipGoals: 'Long-term relationship',
      languages: ['English'],
      zodiacSign: 'Scorpio',
      educationLevel: 'Doctorate',
      jobTitle: 'Physical Therapist',
      company: 'UCSF Medical Center',
      preferences: DiscoveryPreferences(
          minAge: 23,
          maxAge: 32,
          maxDistanceKm: 45,
          showMeGenders: ['Woman'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_11',
      name: 'Mia',
      age: 29,
      gender: 'Woman',
      bio: 'Lawyer by day, baker by weekend 🍪\n\nI object to bad dates!',
      photoUrls: [
        'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400'
      ],
      videoUrls: [],
      interests: ['Law', 'Baking', 'Wine', 'Reading', 'True Crime'],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'never_shut_up',
            answer: 'True crime podcasts - I have theories about every case'),
        ProfilePrompt(
            questionId: 'green_flag',
            answer: 'You bring dessert to dinner parties'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7955,
      longitude: -122.4034,
      distance: 9,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 167,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'French'],
      zodiacSign: 'Gemini',
      educationLevel: 'Juris Doctor',
      jobTitle: 'Corporate Lawyer',
      company: 'Morrison & Foerster',
      preferences: DiscoveryPreferences(
          minAge: 27,
          maxAge: 38,
          maxDistanceKm: 35,
          showMeGenders: ['Man'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_12',
      name: 'Lucas',
      age: 26,
      gender: 'Man',
      bio:
          'Photographer 📷 | World traveler 🌍 | Vinyl collector 🎵\n\nLet me capture your best angles.',
      photoUrls: [
        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400'
      ],
      videoUrls: [],
      interests: ['Photography', 'Travel', 'Vinyl Records', 'Film', 'Art'],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'perfect_date',
            answer:
                'Golden hour photoshoot at a hidden rooftop, then a vinyl listening session'),
        ProfilePrompt(
            questionId: 'go_to_karaoke',
            answer: 'Anything by The Smiths - I commit to the sad vibes'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7749,
      longitude: -122.4194,
      distance: 5,
      distanceUnit: 'km',
      isVerified: false,
      heightCm: 177,
      relationshipGoals: 'Still figuring it out',
      languages: ['English', 'Portuguese'],
      zodiacSign: 'Cancer',
      educationLevel: "Bachelor's degree",
      jobTitle: 'Freelance Photographer',
      preferences: DiscoveryPreferences(
          minAge: 22,
          maxAge: 30,
          maxDistanceKm: 50,
          showMeGenders: ['Woman', 'Non-binary'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_13',
      name: 'Charlotte',
      age: 28,
      gender: 'Woman',
      bio:
          'Veterinarian 🐾 | Plant lady 🌿 | Cozy homebody\n\nMy pets will always come first, but you can be a close second!',
      photoUrls: [
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400'
      ],
      videoUrls: [],
      interests: ['Animals', 'Plants', 'Cooking', 'Hiking', 'Board Games'],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'typical_sunday',
            answer:
                'Farmers market, plant shopping, and cooking a new recipe with my cat supervising'),
        ProfilePrompt(
            questionId: 'green_flag',
            answer: 'You offer to pet-sit without being asked'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7649,
      longitude: -122.4294,
      distance: 11,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 165,
      relationshipGoals: 'Long-term relationship',
      languages: ['English'],
      zodiacSign: 'Virgo',
      educationLevel: 'Doctorate',
      jobTitle: 'Veterinarian',
      company: 'SF SPCA',
      preferences: DiscoveryPreferences(
          minAge: 26,
          maxAge: 35,
          maxDistanceKm: 30,
          showMeGenders: ['Man'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_14',
      name: 'Mandip',
      age: 22,
      gender: 'Man',
      bio:
          'Investment banker 💼 | Pilot on weekends ✈️ | Wine enthusiast 🍷\n\nWork hard, fly harder.',
      photoUrls: [
        'https://www.instagram.com/p/DQcHxf1k8hT/?utm_source=ig_web_copy_link&igsh=NTc4MTIwNjQ2YQ=='
      ],
      videoUrls: [],
      interests: ['Flying', 'Wine', 'Golf', 'Investing', 'Travel'],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'hot_take', answer: 'First class is always worth it'),
        ProfilePrompt(
            questionId: 'perfect_date',
            answer:
                'Scenic flight over Napa, then wine tasting at a private vineyard'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7899,
      longitude: -122.4044,
      distance: 8,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 188,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'French', 'German'],
      zodiacSign: 'Capricorn',
      educationLevel: 'MBA',
      jobTitle: 'Vice President',
      company: 'Goldman Sachs',
      preferences: DiscoveryPreferences(
          minAge: 26,
          maxAge: 35,
          maxDistanceKm: 50,
          showMeGenders: ['Woman'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_15',
      name: 'Zoe',
      age: 24,
      gender: 'Woman',
      bio:
          'Yoga instructor 🧘‍♀️ | Smoothie bowl artist 🥣 | Good vibes only ✨\n\nNamaste in bed.',
      photoUrls: [
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400'
      ],
      videoUrls: [],
      interests: [
        'Yoga',
        'Meditation',
        'Health Food',
        'Nature',
        'Spirituality'
      ],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'change_my_mind',
            answer: 'Mercury retrograde is real and it affects everything'),
        ProfilePrompt(
            questionId: 'typical_sunday',
            answer:
                'Sunrise yoga on the beach, farmers market, then journaling in a cafe'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7599,
      longitude: -122.4094,
      distance: 6,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 170,
      relationshipGoals: 'Still figuring it out',
      languages: ['English'],
      zodiacSign: 'Pisces',
      educationLevel: "Bachelor's degree",
      jobTitle: 'Yoga Instructor',
      company: 'CorePower Yoga',
      preferences: DiscoveryPreferences(
          minAge: 23,
          maxAge: 32,
          maxDistanceKm: 40,
          showMeGenders: ['Man', 'Woman'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_16',
      name: 'Benjamin',
      age: 29,
      gender: 'Man',
      bio:
          'Data scientist 📊 | Board game nerd 🎲 | Amateur comedian\n\nI have a statistically significant sense of humor.',
      photoUrls: [
        'https://images.unsplash.com/photo-1534030347209-467a5b0ad3e6?w=400'
      ],
      videoUrls: [],
      interests: ['Data Science', 'Board Games', 'Comedy', 'Sci-Fi', 'Trivia'],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'hot_take',
            answer: 'Monopoly destroys friendships and should be banned'),
        ProfilePrompt(
            questionId: 'never_shut_up',
            answer:
                'The latest breakthrough in AI - I promise to make it interesting'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7799,
      longitude: -122.4144,
      distance: 10,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 175,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'Python'],
      zodiacSign: 'Aquarius',
      educationLevel: "Master's degree",
      jobTitle: 'Senior Data Scientist',
      company: 'Spotify',
      preferences: DiscoveryPreferences(
          minAge: 24,
          maxAge: 33,
          maxDistanceKm: 45,
          showMeGenders: ['Woman'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_17',
      name: 'Aria',
      age: 26,
      gender: 'Woman',
      bio:
          'Interior designer 🏠 | Thrift queen 👗 | Brunch enthusiast\n\nI can make your space look good and pick the best brunch spot.',
      photoUrls: [
        'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=400'
      ],
      videoUrls: [],
      interests: ['Interior Design', 'Thrifting', 'Brunch', 'Art', 'Fashion'],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'perfect_date',
            answer:
                'Flea market treasure hunting, then mimosas at a rooftop brunch'),
        ProfilePrompt(
            questionId: 'green_flag',
            answer:
                'Your apartment has actual furniture and not just a mattress on the floor'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7649,
      longitude: -122.4194,
      distance: 7,
      distanceUnit: 'km',
      isVerified: false,
      heightCm: 164,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'Italian'],
      zodiacSign: 'Libra',
      educationLevel: "Bachelor's degree",
      jobTitle: 'Interior Designer',
      company: 'Studio McGee',
      preferences: DiscoveryPreferences(
          minAge: 25,
          maxAge: 34,
          maxDistanceKm: 35,
          showMeGenders: ['Man'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_18',
      name: 'Ryan',
      age: 31,
      gender: 'Man',
      bio:
          'ER nurse 🏥 | Marathon runner 🏃 | Craft beer enthusiast 🍺\n\n12-hour shifts make me appreciate my days off even more.',
      photoUrls: [
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400'
      ],
      videoUrls: [],
      interests: ['Running', 'Healthcare', 'Craft Beer', 'Cooking', 'Outdoors'],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'typical_sunday',
            answer:
                'Long run along the Embarcadero, recovery brunch, then brewery hopping'),
        ProfilePrompt(
            questionId: 'change_my_mind',
            answer: 'Running a marathon is easier than dating in SF'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7949,
      longitude: -122.3944,
      distance: 4,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 183,
      relationshipGoals: 'Long-term relationship',
      languages: ['English'],
      zodiacSign: 'Leo',
      educationLevel: "Bachelor's degree",
      jobTitle: 'Emergency Room Nurse',
      company: 'UCSF Medical Center',
      preferences: DiscoveryPreferences(
          minAge: 26,
          maxAge: 36,
          maxDistanceKm: 40,
          showMeGenders: ['Woman'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_19',
      name: 'Luna',
      age: 25,
      gender: 'Woman',
      bio:
          'UX researcher 🔍 | Coffee addict ☕ | Cat mom 🐱\n\nI study how people think, but I still can not figure out dating apps.',
      photoUrls: [
        'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400'
      ],
      videoUrls: [],
      interests: ['UX Research', 'Coffee', 'Cats', 'Psychology', 'Podcasts'],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'hot_take',
            answer: 'Dark mode should be the default for everything'),
        ProfilePrompt(
            questionId: 'never_shut_up',
            answer:
                'How terrible most app designs are - I have strong opinions'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7699,
      longitude: -122.4244,
      distance: 9,
      distanceUnit: 'km',
      isVerified: true,
      heightCm: 161,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'Korean'],
      zodiacSign: 'Capricorn',
      educationLevel: "Master's degree",
      jobTitle: 'UX Researcher',
      company: 'Meta',
      preferences: DiscoveryPreferences(
          minAge: 24,
          maxAge: 32,
          maxDistanceKm: 30,
          showMeGenders: ['Man'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_20',
      name: 'Sebastian',
      age: 28,
      gender: 'Man',
      bio:
          'Music producer 🎧 | Night owl 🦉 | Vinyl enthusiast\n\nI make beats by day and spin records by night.',
      photoUrls: [
        'https://images.unsplash.com/photo-1548372290-8d01b6c8e78c?w=400'
      ],
      videoUrls: [],
      interests: ['Music Production', 'DJing', 'Vinyl', 'Concerts', 'Fashion'],
      profilePrompts: [
        ProfilePrompt(
            questionId: 'go_to_karaoke',
            answer: "I don't do karaoke - I bring the whole DJ setup instead"),
        ProfilePrompt(
            questionId: 'perfect_date',
            answer:
                'Underground music show, then late-night ramen and record shopping'),
      ],
      country: 'United States',
      city: 'San Francisco',
      latitude: 37.7599,
      longitude: -122.4148,
      distance: 6,
      distanceUnit: 'km',
      isVerified: false,
      heightCm: 180,
      relationshipGoals: 'Something casual',
      languages: ['English', 'Spanish'],
      zodiacSign: 'Scorpio',
      educationLevel: "Bachelor's degree",
      jobTitle: 'Music Producer',
      company: 'Independent',
      preferences: DiscoveryPreferences(
          minAge: 22,
          maxAge: 30,
          maxDistanceKm: 50,
          showMeGenders: ['Woman', 'Non-binary'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco'),
    ),
  ].map((profile) {
    return profile.copyWith(
      privacySettings: profile.privacySettings.copyWith(
        showFirstName: true,
      ),
    );
  }).toList();

  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Get already swiped profiles
    final swiped = await _getSwipedProfiles(userId);

    // Filter out swiped profiles
    var available = _mockProfiles.where((p) => !swiped.contains(p.id)).toList();

    // Apply distance filtering if not in passport mode and distance limit is set
    if (!filter.passportModeEnabled && filter.maxDistanceKm != null) {
      final userLat = filter.effectiveLatitude;
      final userLng = filter.effectiveLongitude;

      if (userLat != null && userLng != null) {
        available = available.where((profile) {
          final profileLat = profile.latitude;
          final profileLng = profile.longitude;

          if (profileLat == null || profileLng == null) {
            // Include profiles without location data
            return true;
          }

          final distance = _calculateDistance(
            userLat,
            userLng,
            profileLat,
            profileLng,
          );

          return distance <= filter.maxDistanceKm!;
        }).toList();
      }
    }

    // Shuffle and return
    available.shuffle(_random);
    return available;
  }

  /// Calculate distance between two coordinates using Haversine formula.
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    // Record the swipe
    await _recordSwipe(userId, targetUserId, true);

    // Record the like
    await _recordLike(userId, targetUserId);

    // In stub mode, all mock profiles automatically like the user back
    // so every right swipe creates an instant match for testing/demo
    final matchedProfile = _mockProfiles.firstWhere(
      (p) => p.id == targetUserId,
      orElse: () => _mockProfiles.first,
    );

    final match = CrushMatch(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      otherUserId: targetUserId,
      status: MatchStatus.mutual,
      preMatchMessageRequestsCount: 0,
      pinnedForUser: false,
      otherUserName: matchedProfile.publicDisplayName,
      otherUserPhotoUrl: matchedProfile.photoUrls.isNotEmpty
          ? matchedProfile.photoUrls.first
          : null,
    );

    await _saveMatch(userId, match);

    // Also save match for the other user so they can see it too
    await _saveMatch(
        targetUserId,
        CrushMatch(
          id: match.id,
          userId: targetUserId,
          otherUserId: userId,
          status: MatchStatus.mutual,
          preMatchMessageRequestsCount: 0,
          pinnedForUser: false,
          otherUserName: null,
          otherUserPhotoUrl: null,
        ));

    // Record that the mock profile liked the user back (for consistency)
    await _recordLike(targetUserId, userId);

    return match;
  }

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    await _recordSwipe(userId, targetUserId, false);
  }

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Return top 3 verified profiles as "top picks"
    return _mockProfiles.where((p) => p.isVerified).take(3).toList();
  }

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Return profiles that have liked the current user but haven't been matched yet
    final matches = await _getMatches(userId);
    final matchedIds = matches.map((match) => match.otherUserId).toSet();
    final likesYou = <Profile>[];
    for (final profile in _mockProfiles) {
      final hasLikedUser = await _hasLiked(profile.id, userId);
      if (hasLikedUser) {
        if (!matchedIds.contains(profile.id)) {
          likesYou.add(profile);
        }
      }
    }

    // For demo purposes, if no one has liked the user yet, return some mock profiles
    // that "simulate" having liked the user (helps testing)
    if (likesYou.length < 3) {
      final candidates = _mockProfiles
          .where((profile) =>
              !matchedIds.contains(profile.id) &&
              !likesYou.any((liked) => liked.id == profile.id))
          .toList();
      final preferred =
          candidates.where((profile) => profile.dateOfBirth != null).toList();
      final pool = preferred.isNotEmpty ? preferred : candidates;
      pool.shuffle(_random);
      final needed = (3 - likesYou.length).clamp(0, pool.length);
      final simulatedLikes = pool.take(needed).toList();
      for (final profile in simulatedLikes) {
        await _recordLike(profile.id, userId);
      }
      likesYou.addAll(simulatedLikes);
    }

    return likesYou;
  }

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _getMatches(userId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Set<String>> _getSwipedProfiles(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final swipedJson = prefs.getString('${_swipedKey}_$userId');
    if (swipedJson == null) return {};
    return Set<String>.from(jsonDecode(swipedJson));
  }

  Future<void> _recordSwipe(String userId, String targetId, bool liked) async {
    final prefs = await SharedPreferences.getInstance();
    final swiped = await _getSwipedProfiles(userId);
    swiped.add(targetId);
    await prefs.setString('${_swipedKey}_$userId', jsonEncode(swiped.toList()));
  }

  /// Record that userId liked targetId
  Future<void> _recordLike(String userId, String targetId) async {
    final prefs = await SharedPreferences.getInstance();
    final likesJson = prefs.getString('${_likesKey}_$userId');
    final likes = likesJson != null
        ? Set<String>.from(jsonDecode(likesJson))
        : <String>{};
    likes.add(targetId);
    await prefs.setString('${_likesKey}_$userId', jsonEncode(likes.toList()));
  }

  /// Check if userId has liked targetId
  Future<bool> _hasLiked(String userId, String targetId) async {
    final prefs = await SharedPreferences.getInstance();
    final likesJson = prefs.getString('${_likesKey}_$userId');
    if (likesJson == null) return false;
    final likes = Set<String>.from(jsonDecode(likesJson));
    return likes.contains(targetId);
  }

  Future<void> _saveMatch(String userId, CrushMatch match) async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = prefs.getString('${_matchesKey}_$userId');
    final matches = matchesJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(matchesJson))
        : <Map<String, dynamic>>[];

    matches.add(_matchToJson(match));
    await prefs.setString('${_matchesKey}_$userId', jsonEncode(matches));
  }

  Future<List<CrushMatch>> _getMatches(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = prefs.getString('${_matchesKey}_$userId');
    if (matchesJson == null) return [];

    final matchesList =
        List<Map<String, dynamic>>.from(jsonDecode(matchesJson));
    return matchesList.map((m) => _matchFromJson(m)).toList();
  }

  Map<String, dynamic> _matchToJson(CrushMatch match) {
    return {
      'id': match.id,
      'userId': match.userId,
      'otherUserId': match.otherUserId,
      'status': match.status.name,
      'preMatchMessageRequestsCount': match.preMatchMessageRequestsCount,
      'pinnedForUser': match.pinnedForUser,
      'otherUserName': match.otherUserName,
      'otherUserPhotoUrl': match.otherUserPhotoUrl,
    };
  }

  CrushMatch _matchFromJson(Map<String, dynamic> json) {
    return CrushMatch(
      id: json['id'],
      userId: json['userId'],
      otherUserId: json['otherUserId'],
      status: MatchStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MatchStatus.mutual,
      ),
      preMatchMessageRequestsCount: json['preMatchMessageRequestsCount'] ?? 0,
      pinnedForUser: json['pinnedForUser'] ?? false,
      otherUserName: json['otherUserName'],
      otherUserPhotoUrl: json['otherUserPhotoUrl'],
    );
  }

  @override
  Future<Profile?> fetchProfileById(String profileId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _mockProfiles.firstWhere((p) => p.id == profileId);
    } catch (e) {
      debugPrint(
          'StubDiscoveryRepository: Profile not found for id $profileId: $e');
      return null;
    }
  }

  @override
  Future<CrushMatch?> superLike({
    required String userId,
    required String targetUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    // Record as a like and swipe
    await _recordSwipe(userId, targetUserId, true);
    await _recordLike(userId, targetUserId);

    // In stub mode, super likes always create an instant match for testing/demo
    final matchedProfile = _mockProfiles.firstWhere(
      (p) => p.id == targetUserId,
      orElse: () => _mockProfiles.first,
    );

    final match = CrushMatch(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      otherUserId: targetUserId,
      status: MatchStatus.mutual,
      preMatchMessageRequestsCount: 0,
      pinnedForUser: false,
      otherUserName: matchedProfile.publicDisplayName,
      otherUserPhotoUrl: matchedProfile.photoUrls.isNotEmpty
          ? matchedProfile.photoUrls.first
          : null,
    );

    await _saveMatch(userId, match);
    await _saveMatch(
        targetUserId,
        CrushMatch(
          id: match.id,
          userId: targetUserId,
          otherUserId: userId,
          status: MatchStatus.mutual,
          preMatchMessageRequestsCount: 0,
          pinnedForUser: false,
        ));

    // Record that the mock profile liked the user back (for consistency)
    await _recordLike(targetUserId, userId);

    return match;
  }

  @override
  Future<Profile?> rewindLastSwipe(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final prefs = await SharedPreferences.getInstance();
    final swipedJson = prefs.getString('${_swipedKey}_$userId');
    if (swipedJson == null) return null;

    final swiped = List<String>.from(jsonDecode(swipedJson));
    if (swiped.isEmpty) return null;

    // Remove the last swiped profile
    final lastSwipedId = swiped.removeLast();
    await prefs.setString('${_swipedKey}_$userId', jsonEncode(swiped));

    // Find and return the profile
    try {
      return _mockProfiles.firstWhere((p) => p.id == lastSwipedId);
    } catch (e) {
      debugPrint(
          'StubDiscoveryRepository: Rewound profile not found for id $lastSwipedId: $e');
      return null;
    }
  }
}
