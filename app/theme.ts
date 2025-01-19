import { defaultTheme } from 'react-admin';
import { zhCN } from '@mui/material/locale';

export const theme = {
  ...defaultTheme,
  ...zhCN,
  components: {
    ...defaultTheme.components,
    MuiTextField: {
      defaultProps: {
        variant: 'outlined',
        margin: 'normal',
        fullWidth: true,
      },
    },
    MuiButton: {
      defaultProps: {
        variant: 'contained',
      },
    },
  },
  palette: {
    ...defaultTheme.palette,
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
}; 