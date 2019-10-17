---
layout: post
title: Bevy - Making the camera follow the player
date: 2024-02-18 17:00:46+0100
comments: true
tags: [rust, bug]
---

# Game making in Rust with Bevy

The Rust language has matured to a very stable and usable point.
Now, we are witnessing the growth of the Rust ecosystem.
This does not only involve the integrations being made available by existing platforms (such as client libraries), but also the maturity and variety of frameworks available in the language as well as the patterns for writing and organising code, that developers are discovering.

One such framework is the Bevy game engine, and the (already known) associated pattern - Entity Component System (ECS).

While there are a few game engines available in Rust, Bevy stands out as the most mature, capable, extendable, and practical.

# Entity Component System

The ECS pattern is the fundamental concept driving Bevy's performance and architecture.
Instead of declaring objects and how they interact, developers declare 3 types of elements and bundle them together.

These elements are:
- Entities
- Components
- Systems

Entities are the objects in a game such as players, but also the cameras, lighting, and other elements of rendering.
These have a very rudimentary representation, because they are not meant to carry state, only be identifiers.
You can refer to Entities in the ECS system as sets, such as "all players spawn" or "all cameras move right".

Components are the properties associated with Entities.
Because different Entities can share properties, such as position on a screen, it makes sense to re-use these properties and provide them to the query engine.
So as an example, you could have 2 Entities, such as Player and Tree.
And both these entities could have a Position associated with them, indicating where they are on the screen.
Then you would be able to query "all entities with a position on the screen" and then perform operations on them without needing to know exactly which entity they are.
This is the breakthrough performance benefit of the system - we can now operate on many Entities in parallel, instead of relying on the internal logic of each Entity.

Systems are the logic of a game.
A system is associated with a lifecycle stage of a game, such as setup, or game loop.
A system is also declared with selectors for what they operate on.
In the examples above of how Entities and Comoponents are selected, I used plain English to describe how they are accessed.
In reality, the system elements of Bevy instead use `Query` parameters to indicate what they are associated with.

# Creating a game with a camera that follows the player

For the sake of learning the engine, I want to create a simple 2D game.
Two dimensional games can have several formats.
Side-view, or Top-down (birdseye) views.
They can also have the player move around the screen, or instead have the player be in the centre of the screen and have the world move around the player (relatively).

I have chosen to do top-down and following the player.
This isn't super important, but it does seem to be non-standard for what most people expect from a 2D game.
A lot of the examples online seem to be platformers.

## First approach

I have written the following code as a proof of concept for how the camera would follow the player.

```rust
use bevy::app::PluginGroupBuilder;
use bevy::DefaultPlugins;
use bevy::prelude::*;
use bevy::sprite::MaterialMesh2dBundle;
use bevy::text::BreakLineOn;
use bevy::window::{ExitCondition, WindowMode, WindowResolution};

fn main() {
    app_blocking();
}

#[derive(Component)]
struct Player;

#[derive(Component)]
struct PlayerCamera;

fn app_blocking() {
    App::new()
        .add_plugins(plugins())
        .add_systems(Startup, setup)
        .add_systems(FixedUpdate, (move_player,camera_follow).chain())
        .run();
}

fn plugins() -> PluginGroupBuilder {
    #[cfg(debug_assertions)]
    let window_plugin = WindowPlugin {
        primary_window: Some(Window {
            resizable: false,
            mode: WindowMode::Windowed,
            resolution: WindowResolution::new(800.0, 600.0),
            ..default()
        }),
        exit_condition: ExitCondition::OnPrimaryClosed,
        close_when_requested: true,
    };
    #[cfg(not(debug_assertions))]
        let window_plugin = WindowPlugin {
        primary_window: Some(Window {
            resizable: false,
            mode: WindowMode::BorderlessFullscreen,
            ..default()
        }),
        exit_condition: ExitCondition::OnPrimaryClosed,
        close_when_requested: true,
    };
    DefaultPlugins.set(window_plugin)
}

fn setup(mut commands: Commands, mut meshes: ResMut<Assets<Mesh>>, mut materials: ResMut<Assets<ColorMaterial>>) {
    commands.spawn((Camera2dBundle::default(), PlayerCamera));
    commands.spawn((MaterialMesh2dBundle {
        mesh: meshes.add(shape::Circle::new(50.).into()).into(),
        material: materials.add(ColorMaterial::from(Color::PURPLE)),
        transform: Transform::from_translation(Vec3::new(-150., 0., 0.)),
        ..default()
    }, Player));
    let section = TextSection::new("This is some text", TextStyle::default());
    commands.spawn(Text2dBundle {
        text: Text {
            sections: vec![section],
            alignment: Default::default(),
            linebreak_behavior: BreakLineOn::WordBoundary,
        },
        text_anchor: Default::default(),
        text_2d_bounds: Default::default(),
        transform: Default::default(),
        global_transform: Default::default(),
        visibility: Default::default(),
        inherited_visibility: Default::default(),
        view_visibility: Default::default(),
        text_layout_info: Default::default(),
    });
}

fn move_player(keyboard_input: Res<Input<KeyCode>>, mut query: Query<(&mut Transform, &Player)>) {
    for (mut transform, _player) in query.iter_mut() {
        if keyboard_input.pressed(KeyCode::W) {
            transform.translation.y += 1.0;
        }
        if keyboard_input.pressed(KeyCode::S) {
            transform.translation.y -= 1.0;
        }
        if keyboard_input.pressed(KeyCode::A) {
            transform.translation.x -= 1.0;
        }
        if keyboard_input.pressed(KeyCode::D) {
            transform.translation.x += 1.0;
        }
    }
}

fn camera_follow(
    player_transform: Query<&Transform, With<Player>>,
    mut camera_transform: Query<&mut Transform, With<OrthographicProjection>>,
) {
    camera_transform.single_mut().translation = player_transform.single().translation;
}
```

If we run this, we get the following error.

```
Thread 'main' panicked at /Users/hugh/.cargo/registry/src/index.crates.io-6f17d22bba15001f/bevy_ecs-0.12.1/src/system/system_param.rs:225:5:
error[B0001]: Query<&mut bevy_transform::components::transform::Transform, bevy_ecs::query::filter::With<bevy_render::camera::projection::OrthographicProjection>> in system the_game::camera_follow accesses component(s) bevy_transform::components::transform::Transform in a way that conflicts with a previous system parameter. Consider using `Without<T>` to create disjoint Queries or merging conflicting Queries into a `ParamSet`.
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
Encountered a panic in system `bevy_time::fixed::run_fixed_update_schedule`!
Encountered a panic in system `bevy_app::main_schedule::Main::run_main`!
```

So how do we solve this?

## Overlapping sets for queries

In Rust, you cannot borrow something immutably and mutably at the same time.
Consequently, if we are selecting with two queries, we need to make sure that our mutable borrow from the first query is not included in an immutable borrow of the second query.

Having searched the Bevy Discord with the error message, I managed to find [this discussion](https://discord.com/channels/691052431525675048/1206081799567183922/1206081799567183922).
Alice, one of the developers of Bevy, pointed at this [Github doc](https://github.com/bevyengine/bevy/blob/main/errors/B0001.md) that explains the issue very well.

We can now fix our `camera_follow` code with an exclusion of Transform components that belong to Players!

```rust
fn camera_follow(
    player_transform: Query<&Transform, With<Player>>,
    mut camera_transform: Query<&mut Transform, (With<OrthographicProjection>, Without<Player>)>,
) {
    camera_transform.single_mut().translation = player_transform.single().translation;
}
```

And it works!

Massive thank you to the Bevy community and maintainers for making this easy to navigate.

