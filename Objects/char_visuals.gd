extends Node3D

@onready var alpha_surface: MeshInstance3D = $Alpha_Surface
@onready var alpha_joints: MeshInstance3D = $Alpha_Joints

func accept_skeleton(skeleton : Skeleton3D):
	alpha_surface.skeleton = skeleton.get_path()
	alpha_joints.skeleton = skeleton.get_path()
