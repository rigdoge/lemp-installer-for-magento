'use client';

import { styled } from '@mui/material/styles';
import {
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Divider,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  Storage as StorageIcon,
  Assessment as AssessmentIcon,
  MonitorHeart as MonitorHeartIcon,
  Notifications as NotificationsIcon,
} from '@mui/icons-material';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface SidebarProps {
  open: boolean;
}

const drawerWidth = 240;

const DrawerHeader = styled('div')(({ theme }) => ({
  display: 'flex',
  alignItems: 'center',
  padding: theme.spacing(0, 1),
  ...theme.mixins.toolbar,
  justifyContent: 'flex-end',
}));

const menuItems = [
  { text: '仪表板', icon: <DashboardIcon />, path: '/' },
  { text: 'Magento 站点', icon: <StorageIcon />, path: '/magento' },
  { text: '系统监控', icon: <MonitorHeartIcon />, path: '/monitoring' },
  { text: '日志管理', icon: <AssessmentIcon />, path: '/logs' },
  { text: '通知中心', icon: <NotificationsIcon />, path: '/notifications' },
];

export default function Sidebar({ open }: SidebarProps) {
  const pathname = usePathname();

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: drawerWidth,
          boxSizing: 'border-box',
          ...(open ? {} : {
            width: theme => theme.spacing(7),
            overflowX: 'hidden',
          }),
          transition: theme => theme.transitions.create('width', {
            easing: theme.transitions.easing.sharp,
            duration: theme.transitions.duration.enteringScreen,
          }),
        },
      }}
      open={open}
    >
      <DrawerHeader />
      <Divider />
      <List>
        {menuItems.map((item) => (
          <ListItem
            key={item.text}
            component={Link}
            href={item.path}
            selected={pathname === item.path}
            sx={{
              minHeight: 48,
              justifyContent: open ? 'initial' : 'center',
              px: 2.5,
              '&.Mui-selected': {
                backgroundColor: 'primary.main',
                color: 'primary.contrastText',
                '& .MuiListItemIcon-root': {
                  color: 'primary.contrastText',
                },
                '&:hover': {
                  backgroundColor: 'primary.dark',
                },
              },
            }}
          >
            <ListItemIcon
              sx={{
                minWidth: 0,
                mr: open ? 3 : 'auto',
                justifyContent: 'center',
                color: pathname === item.path ? 'inherit' : 'text.primary',
              }}
            >
              {item.icon}
            </ListItemIcon>
            {open && (
              <ListItemText
                primary={item.text}
                sx={{
                  opacity: open ? 1 : 0,
                  color: pathname === item.path ? 'inherit' : 'text.primary',
                }}
              />
            )}
          </ListItem>
        ))}
      </List>
    </Drawer>
  );
} 