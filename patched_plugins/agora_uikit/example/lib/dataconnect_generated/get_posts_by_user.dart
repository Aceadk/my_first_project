part of 'generated.dart';

class GetPostsByUserVariablesBuilder {
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetPostsByUserVariablesBuilder(this._dataConnect, {required  this.userId,});
  Deserializer<GetPostsByUserData> dataDeserializer = (dynamic json)  => GetPostsByUserData.fromJson(jsonDecode(json));
  Serializer<GetPostsByUserVariables> varsSerializer = (GetPostsByUserVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetPostsByUserData, GetPostsByUserVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetPostsByUserData, GetPostsByUserVariables> ref() {
    GetPostsByUserVariables vars= GetPostsByUserVariables(userId: userId,);
    return _dataConnect.query("GetPostsByUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetPostsByUserPosts {
  final String id;
  final String content;
  final Timestamp createdAt;
  GetPostsByUserPosts.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  content = nativeFromJson<String>(json['content']),
  createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPostsByUserPosts otherTyped = other as GetPostsByUserPosts;
    return id == otherTyped.id && 
    content == otherTyped.content && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, content.hashCode, createdAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['content'] = nativeToJson<String>(content);
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  GetPostsByUserPosts({
    required this.id,
    required this.content,
    required this.createdAt,
  });
}

@immutable
class GetPostsByUserData {
  final List<GetPostsByUserPosts> posts;
  GetPostsByUserData.fromJson(dynamic json):
  
  posts = (json['posts'] as List<dynamic>)
        .map((e) => GetPostsByUserPosts.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPostsByUserData otherTyped = other as GetPostsByUserData;
    return posts == otherTyped.posts;
    
  }
  @override
  int get hashCode => posts.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['posts'] = posts.map((e) => e.toJson()).toList();
    return json;
  }

  GetPostsByUserData({
    required this.posts,
  });
}

@immutable
class GetPostsByUserVariables {
  final String userId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetPostsByUserVariables.fromJson(Map<String, dynamic> json):
  
  userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPostsByUserVariables otherTyped = other as GetPostsByUserVariables;
    return userId == otherTyped.userId;
    
  }
  @override
  int get hashCode => userId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetPostsByUserVariables({
    required this.userId,
  });
}

