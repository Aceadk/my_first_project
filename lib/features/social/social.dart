/// Social feature barrel export.
/// Re-exports all social-related components.
library;

// Domain (Models)
export 'domain/models/compatibility_quiz.dart';
export 'domain/models/date_idea.dart';

// Domain (Repositories)
export 'domain/repositories/compatibility_quiz_repository.dart';
export 'domain/repositories/date_idea_repository.dart';

// Domain (Use Cases)
export 'domain/usecases/social_use_cases.dart';
export 'domain/usecases/complete_quiz.dart';
export 'domain/usecases/get_all_date_ideas.dart';
export 'domain/usecases/get_all_quizzes.dart';
export 'domain/usecases/get_personalized_suggestions.dart';
export 'domain/usecases/get_quiz_result.dart';
export 'domain/usecases/invite_to_quiz.dart';
export 'domain/usecases/remove_saved_idea.dart';
export 'domain/usecases/save_date_idea.dart';
export 'domain/usecases/search_date_ideas.dart';
export 'domain/usecases/send_idea_to_match.dart';
export 'domain/usecases/start_quiz.dart';
export 'domain/usecases/submit_quiz_answer.dart';

// Presentation (BLoC/Cubit)
export 'presentation/bloc/compatibility_quiz_cubit.dart';
export 'presentation/bloc/date_ideas_cubit.dart';

// Presentation (Screens)
export 'presentation/screens/compatibility_quiz_screen.dart';
export 'presentation/screens/date_ideas_screen.dart';
