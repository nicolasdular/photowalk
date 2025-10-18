import { Avatar, AvatarImage } from './ui/avatar';

export function UserAvatar({
  user,
}: {
  user: { name: string; avatar_url: string };
}) {
  return (
    <Avatar>
      <AvatarImage src={user.avatar_url} alt={user.name} />
    </Avatar>
  );
}
