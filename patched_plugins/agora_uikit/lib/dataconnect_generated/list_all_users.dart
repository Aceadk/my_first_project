part of 'generated.dart';

class ListAllUsersVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListAllUsersVariablesBuilder(this._dataConnect, );
  Deserializer<ListAllUsersData> dataDeserializer = (dynamic json)  => ListAllUsersData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListAllUsersData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListAllUsersData, void> ref() {
    
    return _dataConnect.query("ListAllUsers", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListAllUsersUsers {
  final String id;
  final String username;
  final String displayName;
  final String? profilePictureUrl;
  ListAllUsersUsers.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  username = nativeFromJson<String>(json['username']),
  displayName = nativeFromJson<String>(json['displayName']),
  profilePictureUrl = json['profilePictureUrl'] == null ? null : nativeFromJson<String>(json['profilePictureUrl']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllUsersUsers otherTyped = other as ListAllUsersUsers;
    return id == otherTyped.id && 
    username == otherTyped.username && 
    displayName == otherTyped.displayName && 
    profilePictureUrl == otherTyped.profilePictureUrl;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, username.hashCode, displayName.hashCode, profilePictureUrl.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['username'] = nativeToJson<String>(username);
    json['displayName'] = nativeToJson<String>(displayName);
    if (profilePictureUrl != null) {
      json['profilePictureUrl'] = nativeToJson<String?>(profilePictureUrl);
    }
    return json;
  }

  ListAllUsersUsers({
    required this.id,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
  });
}

@immutable
class ListAllUsersData {
  final List<ListAllUsersUsers> users;
  ListAllUsersData.fromJson(dynamic json):
  
  users = (json['users'] as List<dynamic>)
        .map((e) => ListAllUsersUsers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllUsersData otherTyped = other as ListAllUsersData;
    return users == otherTyped.users;
    
  }
  @override
  int get hashCode => users.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['users'] = users.map((e) => e.toJson()).toList();
    return json;
  }

  ListAllUsersData({
    required this.users,
  });
}

