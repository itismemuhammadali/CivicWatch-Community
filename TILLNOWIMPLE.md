# What We Have Built So Far (In Layman Terms)

Here is a simple breakdown of everything that is currently working and implemented in the Vision 1 app:

### 1. User Accounts & Login
- **Sign Up / Log In**: Users can register and log into the app.
- **User Profiles**: Profiles show your information and the public posts you have created.

### 2. Creating a Case (Posting Videos)
- **Uploading Videos/Images**: You can create a new case and upload a video or picture.
- **Top & Bottom Captions**: When you create a post, you can write a "Top Caption" (which shows up like a sticky note on top of the video) and a "Bottom Description" (to explain your argument or story).
- **Tagging a Defendant**: You can select another user to be the "Defendant" in your case.

### 3. The Feed & Discovery
- **Home Feed**: When you open the app, you see a scrollable list of all public cases/videos.
- **Video Player**: Videos play directly in the feed. The Top Caption sits cleanly over the video.
- **Poll Countdown**: Every post has an active countdown timer letting people know how long they have left to vote.

### 4. Voting System (The Jury)
- **Yes / No Voting**: Anyone can watch a video and cast their vote for either the "Owner" (the person who posted) or the "Defendant".
- **Live Counting**: The votes update automatically and are saved directly to the database.

### 5. Comments & Reactions
- **Liking a Post**: You can "Like" a post, and the total like count updates live.
- **Leaving Comments**: You can type out text comments and use emojis from your phone's keyboard.
- **Replying to Comments**: You can reply directly to someone else's comment (nested replies).
- **Liking Comments**: You can like individual comments inside the comment section.

### 6. Behind the Scenes (The Database)
- **Firebase Integration**: We have fully connected the app to a local Firebase Emulator database. All your accounts, posts, votes, and comments are being correctly saved and retrieved from this database.

---
*Currently in Progress: Building the Search Bar and Tagging system (like #topics and @usernames)!*