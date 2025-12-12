// ignore_for_file: prefer_const_constructors_in_immutables, non_constant_identifier_names
part of 'generated.dart';

class LikePostVariablesBuilder {
  String postId;

  final FirebaseDataConnect _dataConnect;
  LikePostVariablesBuilder(this._dataConnect, {required  this.postId,});
  Deserializer<LikePostData> dataDeserializer = (dynamic json)  => LikePostData.fromJson(jsonDecode(json));
  Serializer<LikePostVariables> varsSerializer = (LikePostVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<LikePostData, LikePostVariables>> execute() {
    return ref().execute();
  }

  MutationRef<LikePostData, LikePostVariables> ref() {
    LikePostVariables vars= LikePostVariables(postId: postId,);
    return _dataConnect.mutation("LikePost", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class LikePostLikeInsert {
  final String userId;
  final String postId;
  LikePostLikeInsert.fromJson(dynamic json):
  
  userId = nativeFromJson<String>(json['userId']),
  postId = nativeFromJson<String>(json['postId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final LikePostLikeInsert otherTyped = other as LikePostLikeInsert;
    return userId == otherTyped.userId && 
    postId == otherTyped.postId;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, postId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['postId'] = nativeToJson<String>(postId);
    return json;
  }

  LikePostLikeInsert({
    required this.userId,
    required this.postId,
  });
}

@immutable
class LikePostData {
  final LikePostLikeInsert like_insert;
  LikePostData.fromJson(dynamic json):
  
  like_insert = LikePostLikeInsert.fromJson(json['like_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final LikePostData otherTyped = other as LikePostData;
    return like_insert == otherTyped.like_insert;
    
  }
  @override
  int get hashCode => like_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['like_insert'] = like_insert.toJson();
    return json;
  }

  LikePostData({
    required this.like_insert,
  });
}

@immutable
class LikePostVariables {
  final String postId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  LikePostVariables.fromJson(Map<String, dynamic> json):
  
  postId = nativeFromJson<String>(json['postId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final LikePostVariables otherTyped = other as LikePostVariables;
    return postId == otherTyped.postId;
    
  }
  @override
  int get hashCode => postId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['postId'] = nativeToJson<String>(postId);
    return json;
  }

  LikePostVariables({
    required this.postId,
  });
}
