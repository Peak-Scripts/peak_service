import * as React from "react"

import { cn } from "@/lib/utils"

const Card = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement> & { transparent?: boolean }
>(({ className, transparent = false, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "rounded-lg",
      transparent ? "bg-transparent" : "",
      className
    )}
    style={{
      backgroundColor: transparent ? 'transparent' : undefined,
      background: transparent ? 'transparent' : undefined,
      boxShadow: transparent ? 'none' : undefined,
      border: transparent ? 'none' : undefined
    }}
    {...props}
  />
))
Card.displayName = "Card"

const CardHeader = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement> & { transparent?: boolean }
>(({ className, transparent = false, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex flex-col space-y-1.5 p-6", className)}
    style={{
      backgroundColor: transparent ? 'transparent' : undefined,
      background: transparent ? 'transparent' : undefined
    }}
    {...props}
  />
))
CardHeader.displayName = "CardHeader"

const CardTitle = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "text-2xl font-semibold leading-none tracking-tight",
      className
    )}
    {...props}
  />
))
CardTitle.displayName = "CardTitle"

const CardDescription = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("text-sm text-muted-foreground", className)}
    {...props}
  />
))
CardDescription.displayName = "CardDescription"

const CardContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement> & { transparent?: boolean }
>(({ className, transparent = false, ...props }, ref) => (
  <div 
    ref={ref} 
    className={cn("p-6 pt-0", className)}
    style={{
      backgroundColor: transparent ? 'transparent' : undefined,
      background: transparent ? 'transparent' : undefined
    }}
    {...props} 
  />
))
CardContent.displayName = "CardContent"

const CardFooter = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex items-center p-6 pt-0", className)}
    {...props}
  />
))
CardFooter.displayName = "CardFooter"

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent }
