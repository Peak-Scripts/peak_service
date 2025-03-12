/** @type {import('tailwindcss').Config} */
export default {
    darkMode: ['class'],
    content: ['./src/**/*.{js,jsx,ts,tsx}'],
  theme: {
  	extend: {
  		borderRadius: {
  			lg: 'var(--radius)',
  			md: 'calc(var(--radius) - 2px)',
  			sm: 'calc(var(--radius) - 4px)'
  		},
  		colors: {
  			background: 'hsl(var(--background))',
  			foreground: 'hsl(var(--foreground))',
  			card: {
  				DEFAULT: 'hsl(var(--card))',
  				foreground: 'hsl(var(--card-foreground))'
  			},
  			popover: {
  				DEFAULT: 'hsl(var(--popover))',
  				foreground: 'hsl(var(--popover-foreground))'
  			},
  			primary: {
  				DEFAULT: 'hsl(var(--primary))',
  				foreground: 'hsl(var(--primary-foreground))'
  			},
  			secondary: {
  				DEFAULT: 'hsl(var(--secondary))',
  				foreground: 'hsl(var(--secondary-foreground))'
  			},
  			muted: {
  				DEFAULT: 'hsl(var(--muted))',
  				foreground: 'hsl(var(--muted-foreground))'
  			},
  			accent: {
  				DEFAULT: 'hsl(var(--accent))',
  				foreground: 'hsl(var(--accent-foreground))'
  			},
  			destructive: {
  				DEFAULT: 'hsl(var(--destructive))',
  				foreground: 'hsl(var(--destructive-foreground))'
  			},
  			border: 'hsl(var(--border))',
  			input: 'hsl(var(--input))',
  			ring: 'hsl(var(--ring))',
  			chart: {
  				'1': 'hsl(var(--chart-1))',
  				'2': 'hsl(var(--chart-2))',
  				'3': 'hsl(var(--chart-3))',
  				'4': 'hsl(var(--chart-4))',
  				'5': 'hsl(var(--chart-5))'
  			}
  		},
  		keyframes: {
  			fish: {
  				'0%, 100%': { transform: 'translateX(-50%) rotate(0deg)' },
  				'50%': { transform: 'translateX(-50%) rotate(10deg)' }
  			},
  			shake: {
  				'0%, 100%': { transform: 'translateX(0)' },
  				'10%, 30%, 50%, 70%, 90%': { transform: 'translateX(-3px)' },
  				'20%, 40%, 60%, 80%': { transform: 'translateX(3px)' }
  			},
  			enter: {
  				'0%': { transform: 'translate(-50%, 100%)' },
  				'100%': { transform: 'translate(-50%, 0)' }
  			},
  			slideUp: {
  				'0%': { transform: 'translateY(100%)', opacity: '0' },
  				'100%': { transform: 'translateY(0)', opacity: '1' }
  			},
  			slideDown: {
  				'0%': { transform: 'translateY(0)', opacity: '1' },
  				'100%': { transform: 'translateY(100%)', opacity: '0' }
  			},
  			fadeIn: {
  				'0%': { opacity: '0' },
  				'100%': { opacity: '1' }
  			},
  			fadeOut: {
  				'0%': { opacity: '1' },
  				'100%': { opacity: '0' }
  			}
  		},
  		animation: {
  			fish: 'fish 1s ease-in-out infinite',
  			shake: 'shake 0.5s cubic-bezier(.36,.07,.19,.97) both',
  			enter: 'enter 0.3s ease-out forwards',
  			slideUp: 'slideUp 0.3s ease-out',
  			slideDown: 'slideDown 0.3s ease-out',
  			fadeIn: 'fadeIn 0.3s ease-out',
  			fadeOut: 'fadeOut 0.3s ease-out'
  		}
  	}
  },
  plugins: [require("tailwindcss-animate")],
}
