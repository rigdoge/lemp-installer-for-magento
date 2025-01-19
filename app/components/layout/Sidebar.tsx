import React from 'react';
import { Drawer, List, ListItem, ListItemIcon, ListItemText, useTheme } from '@mui/material';
import DashboardIcon from '@mui/icons-material/Dashboard';
import StorageIcon from '@mui/icons-material/Storage';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

const menuItems = [
  {
    text: '系统概览',
    icon: <DashboardIcon />,
    path: '/'
  },
  {
    text: 'Magento 站点',
    icon: <StorageIcon />,
    path: '/magento'
  }
];

interface SidebarProps {
  open: boolean;
  onClose: () => void;
}

export default function Sidebar({ open, onClose }: SidebarProps) {
  const theme = useTheme();
  const pathname = usePathname();

  return (
    <Drawer
      variant="temporary"
      anchor="left"
      open={open}
      onClose={onClose}
      sx={{
        width: 240,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: 240,
          boxSizing: 'border-box',
          backgroundColor: theme.palette.background.default,
        },
      }}
    >
      <List>
        {menuItems.map((item) => (
          <Link 
            key={item.text} 
            href={item.path}
            style={{ textDecoration: 'none', color: 'inherit' }}
          >
            <ListItem 
              button 
              onClick={onClose}
              selected={pathname === item.path}
            >
              <ListItemIcon>{item.icon}</ListItemIcon>
              <ListItemText primary={item.text} />
            </ListItem>
          </Link>
        ))}
      </List>
    </Drawer>
  );
} 