# AgoraChat-E3kit-Example-android
A chat demo based on AgoraChatSDK (basic chat) and VirgilE3Kit (encryption)

-----------------------------------------------------------------------

## Demo structure

The AgoraChat-E3kit-Example-android folder contains an AgoraChat-E3kit-Example-android project folder.Contains functions related to registration, login and logout and session list encryption session.

The Device class is used to interact with e3kit and DemoHelper is used to managed the device information

## What is encryption chat?

An encrypted session means that only users on both sides of the chat can see the specific content of the current message after receiving the message (the server does not know the content of the message). It protects the privacy of user chat content very well.

The interaction process is as follows
![AgoraChatEThreeProcess](https://user-images.githubusercontent.com/3213611/165893823-c8045a6c-ceec-44c7-baea-b2ad5c1d9ff0.png)


## How to implement encrypted sessions

### We use the group encryption function of VirgilE3Kit to ensure that users can see the historical messages in the local database.

1. We use our own login and registration and then use the token generator of VirgilE3Kit to generate a jwt and then generate the VirgilE3KitSDK object according to the jwt.

2. Use this EThree object to register the current user with VirgilE3Kit.

3. Get the current user's Card object.

4. Use the E3 object to create a VirgilE3Kit.Group object based on the session creator's Card object and the sessionId(This group id is a string sorted by the id of the message sender and the message receiver plus the AgoraChat string).

5. Use the Group object to encrypt and decrypt the corresponding message.

## Using

After downloading the code, enter the AgoraChat-E3kit-Example-android folder in the terminal, and run with AndroidStudio

## Quote

> [Virgil Security document](https://developer.virgilsecurity.com/docs/e3kit/fundamentals/cryptography/)
> [Virgil Security github](https://github.com/VirgilSecurity)
## Extension

At present, this demo function supports single chat. If you want to support the group, you can replace the two parameters of the session created in the demo with the group id and the group creator.
