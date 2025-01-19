'use client';

import { createContext, useContext, useEffect, useState } from 'react';
import { ThemeProvider as MuiThemeProvider, createTheme } from '@mui/material/styles';
import { zhCN } from '@mui/material/locale';

type ThemeMode = 'light' | 'dark';

interface ThemeContextType {
  mode: ThemeMode;
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
}

const createThemeWithMode = (mode: ThemeMode) =>
  createTheme(
    {
      palette: {
        mode,
        primary: {
          main: '#9c27b0',
          light: '#ba68c8',
          dark: '#7b1fa2',
          contrastText: '#ffffff',
        },
        secondary: {
          main: '#ff4081',
          light: '#ff79b0',
          dark: '#c60055',
          contrastText: '#ffffff',
        },
        background: {
          default: mode === 'dark' ? '#0a0014' : '#f3e5f5',
          paper: mode === 'dark' ? '#170029' : '#ffffff',
        },
        text: {
          primary: mode === 'dark' ? '#e1bee7' : '#4a148c',
          secondary: mode === 'dark' ? '#ce93d8' : '#7b1fa2',
        },
        divider: mode === 'dark' ? 'rgba(156, 39, 176, 0.12)' : 'rgba(156, 39, 176, 0.08)',
      },
      components: {
        MuiAppBar: {
          styleOverrides: {
            root: {
              backgroundColor: mode === 'dark' ? '#170029' : '#9c27b0',
            },
          },
        },
        MuiDrawer: {
          styleOverrides: {
            paper: {
              backgroundColor: mode === 'dark' ? '#0a0014' : '#ffffff',
              borderRight: '1px solid',
              borderColor: mode === 'dark' ? 'rgba(156, 39, 176, 0.12)' : 'rgba(156, 39, 176, 0.08)',
            },
          },
        },
        MuiCard: {
          styleOverrides: {
            root: {
              backgroundColor: mode === 'dark' ? '#170029' : '#ffffff',
              borderRadius: 12,
              boxShadow: mode === 'dark' 
                ? '0 4px 6px rgba(156, 39, 176, 0.1)' 
                : '0 4px 6px rgba(156, 39, 176, 0.05)',
            },
          },
        },
        MuiButton: {
          styleOverrides: {
            root: {
              borderRadius: 8,
            },
          },
          defaultProps: {
            variant: 'contained',
          },
        },
        MuiTextField: {
          defaultProps: {
            variant: 'outlined',
            margin: 'normal',
            fullWidth: true,
          },
        },
        MuiPaper: {
          styleOverrides: {
            root: {
              backgroundImage: 'none',
            },
          },
        },
      },
      shape: {
        borderRadius: 8,
      },
      typography: {
        fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
        h1: {
          fontWeight: 500,
          color: mode === 'dark' ? '#e1bee7' : '#4a148c',
        },
        h2: {
          fontWeight: 500,
          color: mode === 'dark' ? '#e1bee7' : '#4a148c',
        },
        h3: {
          fontWeight: 500,
          color: mode === 'dark' ? '#e1bee7' : '#4a148c',
        },
        h4: {
          fontWeight: 500,
          color: mode === 'dark' ? '#e1bee7' : '#4a148c',
        },
        h5: {
          fontWeight: 500,
          color: mode === 'dark' ? '#e1bee7' : '#4a148c',
        },
        h6: {
          fontWeight: 500,
          color: mode === 'dark' ? '#e1bee7' : '#4a148c',
        },
      },
    },
    zhCN
  );

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [mode, setMode] = useState<ThemeMode>('dark');
  const [theme, setTheme] = useState(() => createThemeWithMode(mode));

  useEffect(() => {
    const savedMode = localStorage.getItem('themeMode') as ThemeMode;
    if (savedMode) {
      setMode(savedMode);
      setTheme(createThemeWithMode(savedMode));
    }
  }, []);

  const toggleTheme = () => {
    const newMode = mode === 'light' ? 'dark' : 'light';
    setMode(newMode);
    setTheme(createThemeWithMode(newMode));
    localStorage.setItem('themeMode', newMode);
  };

  return (
    <ThemeContext.Provider value={{ mode, toggleTheme }}>
      <MuiThemeProvider theme={theme}>{children}</MuiThemeProvider>
    </ThemeContext.Provider>
  );
} 