# Basic Usage

Always prioritize using a supported framework over using the generated SDK
directly. Supported frameworks simplify the developer experience and help ensure
best practices are followed.





## Advanced Usage
If a user is not using a supported framework, they can use the generated SDK directly.

Here's an example of how to use it with the first 5 operations:

```js
import { createUser, getPostsByUser, likePost, listAllUsers } from '@dataconnect/generated';


// Operation CreateUser: 
const { data } = await CreateUser(dataConnect);

// Operation GetPostsByUser:  For variables, look at type GetPostsByUserVars in ../index.d.ts
const { data } = await GetPostsByUser(dataConnect, getPostsByUserVars);

// Operation LikePost:  For variables, look at type LikePostVars in ../index.d.ts
const { data } = await LikePost(dataConnect, likePostVars);

// Operation ListAllUsers: 
const { data } = await ListAllUsers(dataConnect);


```