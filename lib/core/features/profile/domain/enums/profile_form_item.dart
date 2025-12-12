enum ProfileFormItem {
  username,
  biography,
  avatar;

  String get value => switch (this) {
    ProfileFormItem.username => 'username',
    ProfileFormItem.biography => 'biography',
    ProfileFormItem.avatar => 'avatar',
  };
}
