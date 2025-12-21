import { ConnectorConfig, DataConnect, QueryRef, QueryPromise, MutationRef, MutationPromise } from 'firebase/data-connect';

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
  user_insert: User_Key;
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
  like_insert: Like_Key;
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

interface CreateUserRef {
  /* Allow users to create refs without passing in DataConnect */
  (): MutationRef<CreateUserData, undefined>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect): MutationRef<CreateUserData, undefined>;
  operationName: string;
}
export const createUserRef: CreateUserRef;

export function createUser(): MutationPromise<CreateUserData, undefined>;
export function createUser(dc: DataConnect): MutationPromise<CreateUserData, undefined>;

interface GetPostsByUserRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetPostsByUserVariables): QueryRef<GetPostsByUserData, GetPostsByUserVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: GetPostsByUserVariables): QueryRef<GetPostsByUserData, GetPostsByUserVariables>;
  operationName: string;
}
export const getPostsByUserRef: GetPostsByUserRef;

export function getPostsByUser(vars: GetPostsByUserVariables): QueryPromise<GetPostsByUserData, GetPostsByUserVariables>;
export function getPostsByUser(dc: DataConnect, vars: GetPostsByUserVariables): QueryPromise<GetPostsByUserData, GetPostsByUserVariables>;

interface LikePostRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: LikePostVariables): MutationRef<LikePostData, LikePostVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: LikePostVariables): MutationRef<LikePostData, LikePostVariables>;
  operationName: string;
}
export const likePostRef: LikePostRef;

export function likePost(vars: LikePostVariables): MutationPromise<LikePostData, LikePostVariables>;
export function likePost(dc: DataConnect, vars: LikePostVariables): MutationPromise<LikePostData, LikePostVariables>;

interface ListAllUsersRef {
  /* Allow users to create refs without passing in DataConnect */
  (): QueryRef<ListAllUsersData, undefined>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect): QueryRef<ListAllUsersData, undefined>;
  operationName: string;
}
export const listAllUsersRef: ListAllUsersRef;

export function listAllUsers(): QueryPromise<ListAllUsersData, undefined>;
export function listAllUsers(dc: DataConnect): QueryPromise<ListAllUsersData, undefined>;

