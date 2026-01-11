/// Chat feature barrel export.
/// Re-exports all chat-related components from their current locations.
library chat;

// Domain (BLoCs, Events, States)
export '../../logic/chat/chat_bloc.dart';
export '../../logic/chat/chat_event.dart';
export '../../logic/chat/chat_state.dart';
export '../../logic/matches/matches_bloc.dart';
export '../../logic/matches/matches_event.dart';
export '../../logic/matches/matches_state.dart';
export '../../logic/call/call_bloc.dart';

// Data (Repositories, Models)
export '../../data/repositories/chat_repository.dart';
export '../../data/repositories/stub/stub_chat_repository.dart';
export '../../data/models/message.dart';
export '../../data/models/match.dart';

// Presentation (Screens)
export '../../presentation/screens/chat_screen.dart';
export '../../presentation/screens/chat_list_screen.dart';
export '../../presentation/screens/matches_screen.dart';
export '../../presentation/screens/call_screen.dart';
