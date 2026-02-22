# System Architecture Diagram
```mermaid
graph TD
    subgraph Client [Flutter App (iOS/Android/Web)]
        UI[Presentation Layer]
        State[State Management / BLoC]
        Domain[Domain Entities & UseCases]
        Data[Data Repositories]
    end

    subgraph Infrastructure
        Http[HTTP Client / Dio]
        FB[Firebase / Firestore]
        WS[WebSocket / Realtime]
        Local[Secure Storage / Hive]
    end

    subgraph Backend Services
        API[Node.js REST API]
        AuthSvc[Authentication Service]
        MatchSvc[Matching Engine]
        ChatSvc[Messaging Service]
    end

    UI --> State
    State --> Domain
    Domain --> Data
    Data --> Http
    Data --> FB
    Data --> WS
    Data --> Local

    Http --> API
    FB --> AuthSvc
    WS --> ChatSvc
```
