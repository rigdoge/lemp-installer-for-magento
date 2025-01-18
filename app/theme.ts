import { createTheme } from '@mui/material/styles';
import { blue } from '@mui/material/colors';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: blue[700],
    },
    background: {
      default: '#1a1a1a',
      paper: '#242424',
    },
  },
});

export default theme; 