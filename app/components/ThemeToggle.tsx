import { IconButton } from '@mui/material';
import Brightness4Icon from '@mui/icons-material/Brightness4';
import Brightness7Icon from '@mui/icons-material/Brightness7';
import { useTheme } from '@mui/material/styles';
import { useContext } from 'react';
import { ColorModeContext } from '../contexts/ColorModeContext';

export default function ThemeToggle() {
  const theme = useTheme();
  const colorMode = useContext(ColorModeContext);

  return (
    <IconButton 
      onClick={colorMode.toggleColorMode} 
      color="inherit"
      sx={{ ml: 1 }}
      aria-label="toggle theme"
    >
      {theme.palette.mode === 'dark' ? <Brightness7Icon /> : <Brightness4Icon />}
    </IconButton>
  );
} 