class Endpoints {
  static const String signUp = '/api/v1/user/createUserBySignUp';
  static const String login = '/api/v1/user/userLogin';
  static const String uploadImage = '/api/v1/application_cloud/upload_image';
  static const String uploadVideo = '/api/v1/application_cloud/upload_video';
  static const String createApplicationAlert =
      '/api/v1/admin_control/createApplicationAlert';
  static const String getAllApplicationAlerts =
      '/api/v1/admin_control/getAllApplicationAlerts';
  static const String createUserCase = '/api/v1/user_case/createUserCase';
  static const String createUserReel = '/api/v1/user_case/create_user_reel';
  static const String getAllActiveReels =
      '/api/v1/user_case/get_all_active_reels';
  static const String getUserReel = '/api/v1/user_case/get_user_reel';
  static const String deleteUserReel = '/api/v1/user_case/delete_user_reel';
  static const String getPendingCasesByUserId =
      '/api/v1/user_case/getPendingCasesByUserId';
  static const String deleteUserCase = '/api/v1/user_case/delete_user_case';
  static const String getPostsByUserId = '/api/v1/case_post/getPostsByUserId';
  static const String getSavedPostByUserId =
      '/api/v1/case_post/getSavedPostByUserId';
  static const String createSavedPost = '/api/v1/case_post/createSavedPost';
  static const String deleteSavedPost = '/api/v1/case_post/deleteSavedPost';
  static const String createPostRepost = '/api/v1/case_post/createPostRepost';
  static const String createPostReport = '/api/v1/case_post/createPostReport';
  static const String remindCasePending =
      '/api/v1/case_post/remind_case_pending';
  Endpoints._();
}
