import React from 'react';
import {
  ChevronDownIcon,
  UserIcon,
  Cog8ToothIcon,
  ShieldCheckIcon,
  LightBulbIcon,
  PlusIcon,
  ArrowRightStartOnRectangleIcon,
} from '@heroicons/react/20/solid';
import { Avatar } from '@catalyst/avatar';
import {
  Dropdown,
  DropdownButton,
  DropdownDivider,
  DropdownItem,
  DropdownLabel,
  DropdownMenu,
} from '@catalyst/dropdown';
import {
  Navbar,
  NavbarDivider,
  NavbarItem,
  NavbarLabel,
  NavbarSection,
  NavbarSpacer,
} from '@catalyst/navbar';
import {
  Sidebar,
  SidebarBody,
  SidebarHeader,
  SidebarItem,
  SidebarLabel,
  SidebarSection,
} from '@catalyst/sidebar';
import { StackedLayout } from '@catalyst/stacked-layout';

const navItems = [{ label: 'Todos', url: '/' }];

function TeamDropdownMenu() {
  return (
    <DropdownMenu className="min-w-80 lg:min-w-64" anchor="bottom start">
      <DropdownItem href="/teams/1/settings">
        <Cog8ToothIcon data-slot="icon" />
        <DropdownLabel>Settings</DropdownLabel>
      </DropdownItem>
      <DropdownDivider />
      <DropdownItem href="/teams/1">
        <Avatar slot="icon" src="/images/logo.svg" />
        <DropdownLabel>Tailwind Labs</DropdownLabel>
      </DropdownItem>
      <DropdownItem href="/teams/2">
        <Avatar
          slot="icon"
          initials="WC"
          className="bg-purple-500 text-white"
        />
        <DropdownLabel>Workcation</DropdownLabel>
      </DropdownItem>
      <DropdownDivider />
      <DropdownItem href="/teams/create">
        <PlusIcon data-slot="icon" />
        <DropdownLabel>New team&hellip;</DropdownLabel>
      </DropdownItem>
    </DropdownMenu>
  );
}

type SignedInLayoutProps = React.PropsWithChildren<{
  onSignOut?: () => void;
  signingOut?: boolean;
  currentTeamName?: string;
  currentUser: any;
}>;

export function SignedInLayout({
  children,
  onSignOut,
  signingOut = false,
  currentTeamName = 'The Stack',
  currentUser,
}: SignedInLayoutProps) {
  console.log(currentUser);
  return (
    <StackedLayout
      navbar={
        <Navbar>
          <Avatar src="/images/logo.svg" className="w-8 h-8" />
          <NavbarLabel>{currentTeamName}</NavbarLabel>
          <NavbarDivider className="max-lg:hidden" />
          <NavbarSection className="max-lg:hidden">
            {navItems.map(({ label, url }) => (
              <NavbarItem key={label} href={url}>
                {label}
              </NavbarItem>
            ))}
          </NavbarSection>
          <NavbarSpacer />
          <NavbarSection>
            <Dropdown>
              <DropdownButton as={NavbarItem}>
                <Avatar src={currentUser.avatar_url} square />
              </DropdownButton>
              <DropdownMenu className="min-w-64" anchor="bottom end">
                <DropdownItem href="/my-profile">
                  <UserIcon data-slot="icon" />
                  <DropdownLabel>My profile</DropdownLabel>
                </DropdownItem>
                <DropdownItem href="/settings">
                  <Cog8ToothIcon data-slot="icon" />
                  <DropdownLabel>Settings</DropdownLabel>
                </DropdownItem>
                <DropdownDivider />
                <DropdownItem href="/privacy-policy">
                  <ShieldCheckIcon data-slot="icon" />
                  <DropdownLabel>Privacy policy</DropdownLabel>
                </DropdownItem>
                <DropdownItem href="/share-feedback">
                  <LightBulbIcon data-slot="icon" />
                  <DropdownLabel>Share feedback</DropdownLabel>
                </DropdownItem>
                <DropdownDivider />
                {onSignOut ? (
                  <DropdownItem onClick={onSignOut} disabled={signingOut}>
                    <ArrowRightStartOnRectangleIcon data-slot="icon" />
                    <DropdownLabel>
                      {signingOut ? 'Signing out…' : 'Sign out'}
                    </DropdownLabel>
                  </DropdownItem>
                ) : (
                  <DropdownItem href="/logout">
                    <ArrowRightStartOnRectangleIcon data-slot="icon" />
                    <DropdownLabel>Sign out</DropdownLabel>
                  </DropdownItem>
                )}
              </DropdownMenu>
            </Dropdown>
          </NavbarSection>
        </Navbar>
      }
      sidebar={
        <Sidebar>
          <SidebarHeader>
            <Dropdown>
              <DropdownButton as={SidebarItem} className="lg:mb-2.5">
                <Avatar src="/images/logo.svg" />
                <SidebarLabel>{currentTeamName}</SidebarLabel>
                <ChevronDownIcon data-slot="icon" />
              </DropdownButton>
              <TeamDropdownMenu />
            </Dropdown>
          </SidebarHeader>
          <SidebarBody>
            <SidebarSection>
              {navItems.map(({ label, url }) => (
                <SidebarItem key={label} href={url}>
                  {label}
                </SidebarItem>
              ))}
            </SidebarSection>
          </SidebarBody>
        </Sidebar>
      }
    >
      {children}
    </StackedLayout>
  );
}
