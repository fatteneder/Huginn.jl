module Huginn


using GtkObservables
using GtkObservables.Gtk
using GtkObservables.Gtk.ShortNames
using CairoMakie
using CairoMakie.Makie
import CairoMakie.Mouse, CairoMakie.MouseEventTypes, CairoMakie.Keyboard


function mousebutton(gtk_button)
    gtk_button == 1 && return Mouse.left
    gtk_button == 2 && return Mouse.middle
    gtk_button == 3 && return Mouse.right
    return Mouse.none
end


function keyboardbutton(gtk_mods)
    ks = Set{Keyboard.Button}()
    gtk_mods & SHIFT > 0   && push!(ks, Keyboard.left_shift)
    gtk_mods & CONTROL > 0 && push!(ks, Keyboard.left_control)
    gtk_mods & MOD1 > 0    && push!(ks, Keyboard.left_super)
    return ks
end


function mousescroll(gtk_scroll)
    gtk_scroll == UP    && return (0,1)
    gtk_scroll == DOWN  && return (0,-1)
    gtk_scroll == LEFT  && return (1,0)
    gtk_scroll == RIGHT && return (-1,0)
    error("Cannot infer mouse scroll from gtk_scroll = $gtk_scroll")
end


function cairo_mwe()

    w, h = Observable(500), Observable(500)
    window = Window("Makie", w[], h[])
    c = canvas(DeviceUnit, w[], h[])
    push!(window, c)

    function drawonto(canvas, figure)
        @guarded draw(canvas) do _
            w[] = Gtk.width(window)
            h[] = Gtk.height(window)
            resize!(figure, w[], h[])
            scene = figure.scene
            screen = CairoMakie.CairoScreen(scene, Gtk.cairo_surface(canvas), getgc(canvas), nothing)
            CairoMakie.cairo_draw(screen, scene)
        end
    end

    f = Figure()
    bbox = f.layout.layoutobservables.computedbbox
    ax = Axis(f[1,1])
    # heatmap!(ax, rand(50, 50))
    lines!(ax, 1:4, 1:4)
    redraw = () -> drawonto(c.widget, f)
    redraw()
    e = events(f.scene)
    e.hasfocus[] = true
    e.entered_window[] = true
    e.window_open[] = true

    onany(w, h) do w, h
        e.window_area[] = Rect2i(0, 0, w[], h[])
    end

    obs = [ getproperty(e, name)
            for name in propertynames(e)
            if getproperty(e, name) isa Observable && name !== :window_area ]
    @guarded onany(obs...) do obs...
        redraw()
    end

    @guarded on(c.mouse.buttonpress) do event
        println("press...")
        x, y = event.position.x, h[] - event.position.y
        prev_pos = e.mouseposition[]
        if (x,y) != prev_pos
            e.mouseposition[] = (x,y)
        end
        btn = mousebutton(event.button)
        if e.mousebutton[] != btn
            e.mousebutton[] = Makie.MouseButtonEvent(btn, Mouse.press)
        end
        kbtn = keyboardbutton(event.modifiers)
        for kb in kbtn
            e.keyboardbutton[] = Makie.KeyEvent(kb, Keyboard.press)
        end
    end
    @guarded on(c.mouse.buttonrelease) do event
        println("release...")
        x, y = event.position.x, h[] - event.position.y
        prev_pos = e.mouseposition[]
        if (x,y) != prev_pos
            e.mouseposition[] = (x,y)
        end
        btn = mousebutton(event.button)
        if e.mousebutton[] != btn
            e.mousebutton[] = Makie.MouseButtonEvent(btn, Mouse.release)
        end
        kbtn = keyboardbutton(event.modifiers)
        for kb in kbtn
            e.keyboardbutton[] = Makie.KeyEvent(kb, Keyboard.release)
        end
    end
    @guarded on(c.mouse.motion) do event
        # println("motion...")
        x, y = event.position.x, h[] - event.position.y
        prev_pos = e.mouseposition[]
        if (x,y) != prev_pos
            e.mouseposition[] = (x,y)
        end
        btn = mousebutton(event.button)
        if e.mousebutton[] != btn
            e.mousebutton[] = Makie.MouseButtonEvent(btn, e.mousebutton[].action)
        end
        kbtn = keyboardbutton(event.modifiers)
        for kb in kbtn
            e.keyboardbutton[] = Makie.KeyEvent(kb, e.keyboardbutton[].action)
        end
    end
    @guarded on(c.mouse.scroll) do event
        # println("scroll...")
        x, y = event.position.x, h[] - event.position.y
        prev_pos = e.mouseposition[]
        if (x,y) != prev_pos
            e.mouseposition[] = (x,y)
        end
        e.scroll[] = mousescroll(event.direction)
        kbtn = keyboardbutton(event.modifiers)
        for kb in kbtn
            e.keyboardbutton[] = Makie.KeyEvent(kb, e.keyboardbutton[].action)
        end
    end

    showall(window)

    return
end


end # module Huginn
