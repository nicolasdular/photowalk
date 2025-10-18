import React from 'react';
import { Link } from '@tanstack/react-router';
import { LogOut } from 'lucide-react';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { UserAvatar } from '@/components/user-avatar';

type SignedInLayoutProps = React.PropsWithChildren<{
  onSignOut?: () => void;
  signingOut?: boolean;
  currentUser: any;
}>;

export function SignedInLayout({
  children,
  onSignOut,
  signingOut = false,
  currentUser,
}: SignedInLayoutProps) {
  const handleSignOut = () => {
    if (onSignOut) {
      onSignOut();
    }
  };

  // Get user initials for avatar fallback
  const getInitials = () => {
    if (currentUser?.name) {
      return currentUser.name
        .split(' ')
        .map((n: string) => n[0])
        .join('')
        .toUpperCase()
        .slice(0, 2);
    }
    return currentUser?.email?.[0]?.toUpperCase() || 'U';
  };

  return (
    <>
      <header>
        <div className="container mx-auto px-4 h-16 flex items-center justify-between">
          <Link
            to="/"
            className="text-xl font-semibold hover:opacity-80 transition-opacity"
          >
            Photowalk
          </Link>

          <DropdownMenu>
            <DropdownMenuTrigger className="focus:outline-none">
              <UserAvatar user={currentUser} />
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem>
                <span>{currentUser.name}</span>
              </DropdownMenuItem>
              <DropdownMenuItem
                onClick={handleSignOut}
                disabled={signingOut}
                className="cursor-pointer"
              >
                <LogOut className="mr-2 h-4 w-4" />
                <span>{signingOut ? 'Signing out…' : 'Sign out'}</span>
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </header>

      <main className="container mx-auto px-4 pb-8 pt-8">{children}</main>
    </>
  );
}
