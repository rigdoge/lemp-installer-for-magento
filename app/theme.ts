import { createTheme } from '@mui/material/styles';
import { zhCN } from '@mui/material/locale';

export const theme = createTheme(
  {
    palette: {
      mode: 'light',
      primary: {
        main: '#1976d2',
      },
      secondary: {
        main: '#dc004e',
      },
      background: {
        default: '#f5f5f5',
        paper: '#ffffff',
      },
    },
    components: {
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
  },
  zhCN
); 