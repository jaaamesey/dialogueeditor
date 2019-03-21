using Godot;
using System;
using System.Windows.Forms;


public class FileDialog : Node
{
    public override void _Ready()
    {
    }

    [STAThread]
    public static string OpenFileDialog()
    {
        var openFileDialog = new OpenFileDialog
        {
            InitialDirectory = "",
            Filter = "All files (*.*)|*.*",
            RestoreDirectory = true
        };

        var result = openFileDialog.ShowDialog();
        if (result == DialogResult.OK)
        {
            var path = openFileDialog.FileName;
            return path;
        }

        return null;
    }

    [STAThread]
    public static string SaveFileDialog()
    {
        var saveFileDialog = new SaveFileDialog
        {
            InitialDirectory = "",
            Filter = "All files (*.*)|*.*",
            RestoreDirectory = true
        };

        var result = saveFileDialog.ShowDialog();
        if (result == DialogResult.OK)
        {
            var path = saveFileDialog.FileName;
            return path;
        }


        return null;
    }
}