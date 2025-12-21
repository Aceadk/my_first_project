import { ConnectorConfig, DataConnect, OperationOptions, ExecuteOperationResponse } from 'firebase-admin/data-connect';

export const connectorConfig: ConnectorConfig;

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;


export interface Comment_Key {
  id: UUIDString;
  __typename?: 'Comment_Key';
}

export interface CreateUserData {
  user_insert: {
    id: UUIDString;
  };
}

export interface Follow_Key {
  followerId: UUIDString;
  followeeId: UUIDString;
  __typename?: 'Follow_Key';
}

export interface GetPostsByUserData {
  posts: ({
    id: UUIDString;
    content: string;
    createdAt: TimestampString;
  } & Post_Key)[];
}

export interface GetPostsByUserVariables {
  userId: UUIDString;
}

export interface LikePostData {
  like_insert: {
    userId: UUIDString;
    postId: UUIDString;
  };
}

export interface LikePostVariables {
  postId: UUIDString;
}

export interface Like_Key {
  userId: UUIDString;
  postId: UUIDString;
  __typename?: 'Like_Key';
}

export interface ListAllUsersData {
  users: ({
    id: UUIDString;
    username: string;
    displayName: string;
    profilePictureUrl?: string | null;
  } & User_Key)[];
}

export interface Post_Key {
  id: UUIDString;
  __typename?: 'Post_Key';
}

export interface User_Key {
  id: UUIDString;
  __typename?: 'User_Key';
}

/** Generated Node Admin SDK operation action function for the 'CreateUser' Mutation. Allow users to execute without passing in DataConnect. */
export function createUser(dc: DataConnect, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateUserData>>;
/** Generated Node Admin SDK operation action function for the 'CreateUser' Mutation. Allow users to pass in custom DataConnect instances. */
export function createUser(options?: OperationOptions): Promise<ExecuteOperationResponse<CreateUserData>>;

/** Generated Node Admin SDK operation action function for the 'GetPostsByUser' Query. Allow users to execute without passing in DataConnect. */
export function getPostsByUser(dc: DataConnect, vars: GetPostsByUserVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetPostsByUserData>>;
/** Generated Node Admin SDK operation action function for the 'GetPostsByUser' Query. Allow users to pass in custom DataConnect instances. */
export function getPostsByUser(vars: GetPostsByUserVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetPostsByUserData>>;

/** Generated Node Admin SDK operation action function for the 'LikePost' Mutation. Allow users to execute without passing in DataConnect. */
export function likePost(dc: DataConnect, vars: LikePostVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<LikePostData>>;
/** Generated Node Admin SDK operation action function for the 'LikePost' Mutation. Allow users to pass in custom DataConnect instances. */
export function likePost(vars: LikePostVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<LikePostData>>;

/** Generated Node Admin SDK operation action function for the 'ListAllUsers' Query. Allow users to execute without passing in DataConnect. */
export function listAllUsers(dc: DataConnect, options?: OperationOptions): Promise<ExecuteOperationResponse<ListAllUsersData>>;
/** Generated Node Admin SDK operation action function for the 'ListAllUsers' Query. Allow users to pass in custom DataConnect instances. */
export function listAllUsers(options?: OperationOptions): Promise<ExecuteOperationResponse<ListAllUsersData>>;

